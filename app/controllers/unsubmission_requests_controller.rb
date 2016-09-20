class UnsubmissionRequestsController < ApplicationController
  def new
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || @questionnaire.closed? || !current_user.authorized_submitter_of?(@questionnaire) || !current_user.submitted?(@questionnaire)
  end

  def create
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || @questionnaire.closed? || !current_user.authorized_submitter_of?(@questionnaire) || !current_user.submitted?(@questionnaire)
    auth = current_user.authorized_submitters.find_by_questionnaire_id(@questionnaire.id)
    auth.requested_unsubmission = true
    auth.save
    url = "http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")
    UserMailer.request_unsubmission(current_user, @questionnaire, params[:subject], params[:body], url).deliver
    redirect_to root_url
  end
end
