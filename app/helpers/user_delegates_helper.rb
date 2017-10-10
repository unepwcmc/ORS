module UserDelegatesHelper
  def select_existing_delegate(form)
    return '' unless current_user.role?(:admin)
    content_tag(:div, class: 'select-delegate form-section') do
      content_tag(:span, class: 'subtitle') do
        t('user_delegates.select_delegate')
      end +
      content_tag(:span, class: 'select-delegate-dropdown') do
        form.select :delegate_id, @delegates.collect{ |d| [d.full_name, d.id] }, {include_blank: 'Select a delegate...'}
      end
    end +
    content_tag(:div, '', class: 'border-bottom')
  end

  def help_text
    content = ''
    if current_user.role?(:admin)
      content = raw(t('user_delegates.help_text'))
    elsif current_user.id == @user_delegate.delegate_id
      content =
        """
          #{t('manage_delegates.u_are_delegate')}
          #{h @user_delegate.user.full_name}.
          #{t('manage_delegates.delegate_show_help')}
        """
    elsif current_user.id == @user_delegate.user_id
      content =
        """
          #{t('manage_delegates.u_are_delegator')}
          #{h @user_delegate.delegate.full_name}.
        """
    end
    content_tag(:p, content)
  end
end
