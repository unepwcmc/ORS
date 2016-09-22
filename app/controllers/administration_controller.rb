class AdministrationController < ApplicationController

  def index
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || !current_user.role?(:admin)
    @questionnaires = {}
    @questionnaires[:edited] = Questionnaire.last_edited(5)
    @questionnaires[:created] = Questionnaire.last_created(5)
    @questionnaires[:activated] = Questionnaire.last_activated(5)
    @users = User.last_created(5)
  end

end
