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
end
