class RespondentAdminController < ApplicationController

  def index
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || !current_user.role?(:respondent_admin)
    @questionnaires = Questionnaire.order('created_at DESC')
  end

end
