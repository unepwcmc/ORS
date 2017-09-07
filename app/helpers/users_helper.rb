module UsersHelper
  def selected_loop_item(filtering_field_id, user_id)
    obj = UserFilteringField.find_by_filtering_field_id_and_user_id(filtering_field_id, user_id)
    obj.present? ? obj.field_value : nil
  end

  def select_delegation_questionnaire(form, user, user_delegate=nil)
    if user.available_questionnaires.present?
      form.fields_for :delegations, form.object.delegations.build do |f|
        f.select(
          :questionnaire_id,
          user.available_questionnaires.collect{|p| [h(p.title(I18n.locale.to_s)[0,50])+"...", p.id] },
          { include_blank: t('manage_delegates.select_a_q'), selected: selected_questionnaire_id_for(user, user_delegate) },
          class: 'select-delegation-questionnaire'
        )
      end
    else
      t('delegation_details.no_questionnaires_available')
    end
  end

  def is_respondent_of?(user_delegate, respondent)
    user_delegate.delegators.include?(respondent)
  end

  def selected_questionnaire_id_for(respondent, user_delegate)
    delegations       = respondent.delegations
    user_delegate_obj = delegations.map(&:user_delegate).find{|ud| ud.delegate_id == user_delegate.id }
    delegation        = delegations.find {|d| d.user_delegate == user_delegate_obj }
    delegation.try(:questionnaire).try(:id)
  end
end
