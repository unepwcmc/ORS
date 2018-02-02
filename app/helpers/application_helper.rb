# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def is_administration_page?
    # Used in navigation to identify if the page is an admin page or not
    !current_page_is_a_submission_page? ||
    current_page?(administration_path) ||
    current_page?(new_questionnaire_path) ||
    current_page?(duplicate_questionnaires_path) ||
    current_page?(questionnaires_path) ||
    current_page?(search_questionnaires_path) ||
    current_page?(reminders_path) ||
    current_page?(new_reminder_path) ||
    ( params[:controller] == 'questionnaires' && params[:action] == 'dashboard' ) ||
    ( params[:controller] == 'questionnaires' && params[:action] == 'manage_languages' ) ||
    ( params[:controller] == 'questionnaires' && params[:action] == 'respondents' ) ||
    ( params[:controller] == 'questionnaires' && params[:action] == 'structure_ordering' ) ||
    ( params[:controller] == 'questionnaires' && params[:action] == 'communication_details' ) ||
    ( params[:controller] == 'authorized_submitters' ) ||
    ( params[:controller] == 'loop_sources' ) ||
    ( params[:controller] == 'deadlines' ) ||
    ( params[:controller] == 'filtering_fields' ) ||
    ( params[:controller] == 'questionnaires' && params[:action] == 'show' ) ||
    ( params[:controller] == 'sections' && params[:action] == 'define_dependency' )
  end

  def current_page_is_a_submission_page?
    current_page?(root_path) ||
    (params[:controller] == 'user_delegates'  && params[:user_id].to_i == current_user.id) ||
    (params[:controller] == 'users'           && params[:action] == 'edit'  && params[:id].to_i == current_user.id) ||
    (params[:controller] == 'users'           && params[:action] == 'show'  && params[:id].to_i == current_user.id)
  end

  def main_nav_link_with_class title, path
    puts params.inspect
    if path == administration_path || path == respondent_admin_path
      classes = is_administration_page? ? 'current' : ''
    else
      classes = !is_administration_page? ? 'current' : ''
    end

    link_to title, path, class: classes
  end

  def sub_nav_link_with_class title, path
    classes = current_page?(path) ? 'current' : ''
    link_to title, path, class: classes, title: title
  end

  def remove_child_link(name, f, link_class=nil)
    f.hidden_field(:_destroy) + link_to(name, "javascript:void(0)", :class => link_class ? link_class : "remove_child")
  end

  #folder param: in case the partial is not in the form_builder.object folder
  def new_child_fields_template(form_builder, association, content_type=:div, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(association).klass.new
    options[:partial] ||= form_builder.object.class.to_s.underscore.pluralize + "/"+ association.to_s.singularize
    options[:form_builder_local] ||= :f
    #content_for :jstemplates do
    content_tag(content_type, :id => "#{association}_fields_template", :class => "hide") do
      form_builder.fields_for(association, options[:object], :child_index => "new_#{association}") do |f|
        render(:partial => options[:partial], :locals => {options[:form_builder_local] => f, :aux_builder => form_builder})
      end
    end
  end

  def add_child_link(name, association, link_class=nil)
    link_to(name, "javascript:void(0)", :class => link_class ? link_class : "add_child", :"data-association" => association )
  end

  def tooltip(title, text)
    fa_icon('info-circle',
            alt: 'Info',
            :title => Sanitize.clean(title, OrtSanitize::Config::ORT) + " - " +
            Sanitize.clean(text, OrtSanitize::Config::ORT),
            :class => "obj_tooltip info info-icon--blue")
  end

  def info_tip title, text
    fa_icon('info-circle',
            alt: 'Info',
            title: Sanitize.clean(title, OrtSanitize::Config::ORT) + " - " +
            Sanitize.clean(text, OrtSanitize::Config::ORT),
            class: 'obj_tooltip info info-icon--blue'
           )
  end

  #new function which displays a moving flag to attract attention
  def info_tip_remark(title,text)
    fa_icon('info-circle',
            alt: 'Info',
            title: Sanitize.clean(title, OrtSanitize::Config::ORT) + " - " +
            Sanitize.clean(text, OrtSanitize::Config::ORT),
            class: 'obj_tooltip info info-icon--blue'
           )
  end

  #returns the object_fields from the builder object, with language :language
  # or builds a new object with :language if it doesn't exist
  def get_field_object_in language, association, f
    ( f.object.send(association.to_s).find_by_language(language) || f.object.send(association.to_s).build(:language => language) )
  end

  #Returns the identifier composed of the part id and the looping_identifier, if this is present
  def append_identifier part, looping_identifier
    part.id.to_s + (looping_identifier.present? ? "_#{looping_identifier}" : "_0")
  end

  def set_header
    link_to h( ApplicationProfile.title), (current_user && current_user.role?(:admin)) ? administration_path : ( current_user ? root_url : root_url(:lang => (params[:lang]||"en")) )
  end

  def application_profile_logo
    logo_path = ApplicationProfile.logo_path
    if logo_path.present?
      link_to root_path do
        image_tag logo_path
      end
    end
  end

  def subnavigation(&block)
    content_tag(:div, {id: 'nav-level-2', class: 'row'}) do
      content_tag(:div, content_for(:subnav), {class: 'container'})
    end
  end
end
