class AuthorizedSubmittersController < ApplicationController

  authorize_resource

  # GET /questionnaires/:questionnaire_id/authorized_submitters
  def index
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    @users = (User.submitters - @questionnaire.user_delegates.map(&:delegate).flatten) #=> all submitters
    @groups = User.group_counts
    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  def authorize
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    url = "http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")
    @users = AuthorizedSubmitter.authorize_from_array_of_users(params[:users], @questionnaire, url, params[:disable_emails]) if params[:users]
    if @users.present?
      flash[:notice] = "Authorisation successfully granted"
    end
    respond_to do |format|
      format.js
    end
  end

  def remove
    questionnaire = Questionnaire.find(params[:questionnaire_id])
    url = "http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")
    @users = AuthorizedSubmitter.remove_authorization_from_array_of_users(params[:users], questionnaire, url) if params[:users]
    if @users.present?
      flash[:notice] = "Authorisation successfully removed"
    end
    respond_to do |format|
      format.js
    end
  end

  def change_language
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    if @questionnaire
      authorized_submitter = current_user.authorized_to_answer? @questionnaire
      if authorized_submitter
        authorized_submitter.language = params[:language][0]
        authorized_submitter.save
        respond_to do |format|
          format.html { redirect_to submission_questionnaire_path(@questionnaire) }
        end
      else
        raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
      end
    end
  end
end
