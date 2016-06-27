# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

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
        render(:partial => options[:partial], :locals => { options[:form_builder_local] => f, :aux_builder => form_builder })
      end
    end
  end

  def add_child_link(name, association, link_class=nil)
    link_to(name, "javascript:void(0)", :class => link_class ? link_class : "add_child", :"data-association" => association )
  end

  def tooltip(title, text)
    image_tag('icons/qmark.png', :size => "20x20",
              :title => Sanitize.clean(title, OrtSanitize::Config::ORT) + " - " + Sanitize.clean(text, OrtSanitize::Config::ORT),
              :class => "obj_tooltip", :alt => "Tooltip")
  end

  def info_tip title, text
    image_tag(
      'icons/info.png', 
      :size => "15x15", 
      :title => Sanitize.clean(title, OrtSanitize::Config::ORT) + " - " + 
       Sanitize.clean(text, OrtSanitize::Config::ORT), 
      :class => "obj_tooltip", 
      :alt => "Info"
    )
  end
  
  #new function which displays a moving flag to attract attention
  def info_tip_remark(title,text)
    image_tag('icons/info.png', :size => "15x15", :title => h(title) + " - " + h(text), :class => "obj_tooltip", :alt => "Info")
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
end
