module QuestionnairesHelper

  def display_loop_sources_of questionnaire
    sources = []
    questionnaire.loop_sources.each do |source|
      li_obj = "<li id='source_#{source.id.to_s}'>#{link_to h(source.name), loop_source_path(source)}: "
      case source.parse_status
        when 0
          li_obj << "Source being uploaded."
        when 1
          li_obj << "[ " + source.loop_item_type.self_and_descendants.map{ |item| ( item.is_filtering_field? ? "<strong>#{h(item.name)}</strong>": "#{h(item.name)}" )+" "+ (item.is_filtering_field? ? "*" : "") }.join(" > ") + " ] " if source.loop_item_type
          li_obj << "#{link_to "Remove", loop_source_path(source), :method => :delete, :class => "delete confirm_deletion", :confirm_text => "Are you sure you want to delete this loop source?\n Any related elements will be modified accordingly" + (questionnaire.source_questionnaire.present? ? " and any associated answers will be deleted." : ".")}</li>"
        when 2
          li_obj << "There were some errors uploading this source, please go to the loop source page for details. "
          li_obj << "#{link_to "Remove", loop_source_path(source), :method => :delete, :class => "delete confirm_deletion", :confirm_text => "Are you sure you want to delete this loop source?\n Any related elements will be modified accordingly" + (questionnaire.source_questionnaire.present? ? " and any associated answers will be deleted." : ".")}</li>"
      end
      sources << li_obj
    end
    sources
  end

  def due_warning_basic_message questionnaire, url
    returning text="" do
      text << "The following questionnaire is due on #{Time.now.strftime("%H:%M:%S %B %d, %Y")}:\n\n"
      text << "Title: #{questionnaire.title}\n"
      text << "Default language: #{questionnaire.language_english_name}\n"
      text << "Available languages: #{questionnaire.questionnaire_fields.map{ |a| a.language_english_name }.join(', ')}\n"
      text << "Year: #{questionnaire.questionnaire_date.strftime('%Y')}\n\n"
      text << "Please go to #{url}/questionnaires/#{questionnaire.id}/submission to finish your answers and submit it.\n"
      text << "The questionnaire is also available through your dashboard.\n\n"
      text << "Best regards,\n"
      text << "The #{ApplicationProfile.title} team"
    end
  end

  INFO_ADD_TEXT = {
    "section" => "Add section - By clicking here you will be presented with a form to add a new section to the questionnaire. This new section will be added as a root section of the questionnaire.",

    "question" => "Clicking here will present you with a form to add a new question to the questionnaire. The new question will be added as a sibling of this question.",

    "sub_section" => "Presents you with a form to add a new sub section to this section."
  }
  def render_add_button(button, questionnaire)
    if questionnaire.inactive?
      if "preview" != controller.action_name
         info_tip_text = INFO_ADD_TEXT[button]

        content_tag('div', class: "add-questionnaire-part-btn") do
          content_tag('i', '', class: "fa fa-plus-circle") +
          link_to("Add #{button}", "#", {
            id: "show_add_#{button}",
            title: info_tip_text
          })
        end
      end
    end
  end

  INFO_DELETE_TEXT = {
    "section" => "Allows you to delete this section",
    "question" => "Allows you to delete this question"
  }
  def render_delete_button(button, questionnaire, path)
    if questionnaire.inactive?
      if "preview" != controller.action_name
        info_tip_text = INFO_DELETE_TEXT[button]
        confirmation_text = "Are you sure you want to delete this #{button}?"
        if button == "section"
          confirmation_text << "\nAll sub-sections and questions will also be lost!"
        end
        content_tag('div', class: "delete-questionnaire-part-btn") do
          content_tag('i', '', class: "fa fa-minus-circle") +
          link_to("Delete #{button}", path, {
            id: "show_delete_#{button}",
            title: info_tip_text,
            method: :delete,
            confirm: confirmation_text
          })
        end
      end
    end
  end

  INFO_PREVIEW_TEXT = {
    "section" => "<p>Takes you to a page where you can define a relation of dependency for this section. Defining which conditions must be met for it to be displayed.</p>",

    "questionnaire" => "<p>Displays a quick preview of the questionnaire as a whole.</p>"
  }
  def render_preview_button(part_type, part)
    path = send("preview_#{part_type}_path", part.id)
    link_to("Preview", path, class: "preview-btn #{part_type}-preview-btn get li_tooltip btn btn-secondary btn-fixed-size", title: "Preview #{part_type} - #{INFO_PREVIEW_TEXT[part_type]}")
  end

  INFO_CLOSE_PREVIEW_TEXT = {
    "section" => "<p>Takes you the main page of this section, where you can see its information and access the options to add new sub sections or questions to it.</p>",

    "questionnaire" => "<p>Takes you to the page where you can see this questionnaire information and structure, where you can edit it, add new sections to it and navigate in its structure.</p>"
  }
  def render_close_preview_button(part_type, part)
    path = part_type == "section" ? @section : questionnaire_path(@questionnaire)

    classes = part_type == "section" ? "get li_tooltip" : ""

    link_to("Close preview", path, class: "#{classes} close-preview-btn #{part_type}-close-preview-btn btn btn-secondary btn-fixed-size", title: "#{part_type} - #{INFO_CLOSE_PREVIEW_TEXT[part_type]}")
  end

  def language_angle_icon(field)
    klass = field.is_default_language? ? 'fa fa-angle-up' : 'fa fa-angle-down'
    content_tag(:i, '', class: klass)
  end

  def content_field(title, content)
    content_tag(:div, class: title.downcase.tr(" ", "_")) do
      content_tag(:div, class: "row padded") do
        content_tag(:div, class: "col") do
          content_tag(:strong, title)
        end
      end +
      if content.present?
        content_tag(:div, class: "row padded") do
          content_tag(:div, class: "col field-content") do
            content
          end
        end
      end
    end
  end

  def default_language_tag
    content_tag(:div, class: 'default-language-tag') do
      "Default"
    end
  end

  def cannot_edit_message questionnaire
    if questionnaire.active?
      content_tag(:div, class: 'row group padded cannot-edit') do
        concat "This questionnaire has been activated. You’ll need to "
        concat link_to("deactivate this questionnaire", dashboard_questionnaire_path(questionnaire))
        concat " before editing it."
      end
    end
  end

  def cannot_submit_message questionnaire
    if questionnaire.inactive?
      content_tag(:div, class: 'row group padded cannot-edit') do
        "This questionnaire has been deactivated."
      end
    end
  end

  def collapse_buttons section
    collapsed = section.starts_collapsed?
    content_tag(:li, class: "show_info btn #{collapsed ? '' : 'hide'}") do
      link_to(raw(t('s_details.expand') + " " + fa_icon("caret-down")), "#")
    end +
    content_tag(:li, class: "hide_info btn #{collapsed ? 'hide' : ''}") do
      link_to(raw(t('s_details.collapse') + " " + fa_icon("caret-up")), "#")
    end
  end

  def respondents_page_link(title, path)
    if current_user.role?(:admin)
      link_to h(title), path
    else
      h(title)
    end
  end

  def manage_respondents_filtering_fields
    if current_user.role?(:admin)
      "#{h(@questionnaire.authorized_submitters.count)} (#{link_to("Manage", questionnaire_authorized_submitters_path(@questionnaire))})".html_safe
    else
      ''
    end
  end
end
