module QuestionnairesHelper

  def display_loop_sources_of questionnaire
    sources = []
    questionnaire.loop_sources.each do |source|
      li_obj = "<li id='source_#{source.id.to_s}'>#{link_to h(source.name), loop_source_path(source)}: "
      case source.parse_status
        when 0
          li_obj << "Source being uploaded."
        when 1
          li_obj << "[ " + source.loop_item_type.self_and_descendants.map{|item| ( item.is_filtering_field? ? "<strong>#{h(item.name)}</strong>": "#{h(item.name)}" )+" "+ (item.is_filtering_field? ? "*" : "")}.join(" > ") + " ] " if source.loop_item_type
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
      text << "Available languages: #{questionnaire.questionnaire_fields.map{|a| a.language_english_name}.join(', ')}\n"
      text << "Year: #{questionnaire.questionnaire_date.strftime('%Y')}\n\n"
      text << "Please go to #{url}/questionnaires/#{questionnaire.id}/submission to finish your answers and submit it.\n"
      text << "The questionnaire is also available through your dashboard.\n\n"
      text << "Best regards,\n"
      text << "The #{ApplicationProfile.title} team"
    end
  end
end
