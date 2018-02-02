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

  def manage_delegates_title(current_user, user)
    return '' unless user || current_user
    if user.id != current_user.id && current_user.role?(:admin)
      title = user.is_delegate? ? t('manage_delegates.admin_delegate_title') : t('manage_delegates.admin_title')
      "#{title} #{user.full_name}"
    else
      user.is_delegate? ? t('manage_delegates.manage_your_delegators') : t('manage_delegates.manage_your_delegates')
    end
  end

  def delegates_list_title(current_user, user)
    title = t('manage_delegates.user_has_delegates')
    return title unless user || current_user
    if user.id != current_user.id && current_user.role?(:admin)
      "#{user.full_name} #{title}"
    else
      t('manage_delegates.u_have_delegates')
    end
  end

  def delegators_list_title(current_user, user)
    title = t('manage_delegates.user_is_a_delegate')
    return title unless user || current_user
    current_user.role?(:admin) ? "#{user.full_name} #{title}" : title
  end

  def add_delegate_button
    user = @user && current_user.role?(:admin) ? @user : current_user
    link_to t('user_new.add_delegate'), new_user_user_delegate_path(user), class: 'btn'
  end

end
