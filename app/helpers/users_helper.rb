module UsersHelper
  def selected_loop_item(filtering_field_id, user_id)
    obj = UserFilteringField.find_by_filtering_field_id_and_user_id(filtering_field_id, user_id)
    obj.present? ? obj.field_value : nil
  end

  def select_delegation_questionnaire(user)
    if user.available_questionnaires.present?
      select "delegation", "questionnaire_id", user.available_questionnaires.collect{|p| [h(p.title(I18n.locale.to_s)[0,50])+"...", p.id] }, { include_blank: t('manage_delegates.select_a_q') }, class: 'select-delegation-questionnaire'
    else
      t('delegation_details.no_questionnaires_available')
    end
  end
end
