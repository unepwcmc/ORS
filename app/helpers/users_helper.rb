module UsersHelper
  def selected_loop_item(filtering_field_id, user_id)
    obj = UserFilteringField.find_by_filtering_field_id_and_user_id(filtering_field_id, user_id)
    obj.present? ? obj.field_value : nil
  end

  def select_delegation_questionnaire(form, user)
    if user.available_questionnaires.present?
      form.fields_for :delegations, form.object.delegations.build do |f|
        f.select :questionnaire_id, user.available_questionnaires.collect{|p| [h(p.title(I18n.locale.to_s)[0,50])+"...", p.id] }, { include_blank: t('manage_delegates.select_a_q') }, class: 'select-delegation-questionnaire'
      end
    else
      t('delegation_details.no_questionnaires_available')
    end
  end

  def manage_delegates_title(user)
    return '' unless user
    title = t('manage_delegates.admin_title')
    user.role?(:admin) ? "#{title} #{user.full_name}" : title
  end

  def delegates_list_title(user)
    return '' unless user
    title = t('manage_delegates.user_has_delegates')
    user.role?(:admin) ? "#{user.full_name} #{title}" : title
  end
end
