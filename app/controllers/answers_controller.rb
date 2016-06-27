class AnswersController < ApplicationController

  before_filter :set_current_user_delegate

  def update
    @answer = Answer.find(params[:id])
    @authorization = current_user ? current_user.authorization_for(@answer.question, @current_user_delegate.id) : false
    #raise an AccessDenied Exception if the answer doesn't belong to this user (if its a respondent)
    #or if it wasn't last edited by the current_user (so that the delegates can update their own answers
    #but not the respondets answers.)
    #TODO: Verify if this is desired behavior
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    if params[:to_render] == "save_links"
      Answer.validate_the_urls(params[:answer])
    end
    if @answer.update_attributes(params[:answer])
      flash[:notice] = "Changes successfully made."
      @success = true
    else
      flash[:error] = "There was a problem when saving your changes, please try again."
      @success = false
    end
    respond_to do |format|
      format.js { render params[:to_render] }
    end
  end

  def add_document
    @question = Question.find(params[:id])
    @authorization = current_user ? current_user.authorization_for(@question, @current_user_delegate.id) : false
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    I18n.locale = @authorization[:language]
    @answer = Answer.find_or_create_by_question_id_and_questionnaire_id_and_user_id_and_looping_identifier(@question.id, @question.section.root.questionnaire.id, @authorization[:user].id, params[:looping_identifier])
    @answer.documents.build
    respond_to do |format|
      format.js
    end
  end

  def add_links
    @question = Question.find(params[:id])
    @authorization = current_user ? current_user.authorization_for(@question, @current_user_delegate.id) : false
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    I18n.locale = @authorization[:language]
    @answer = Answer.find_or_create_by_question_id_and_questionnaire_id_and_user_id_and_looping_identifier(@question.id, @question.section.root.questionnaire.id, @authorization[:user].id, params[:looping_identifier])
    @answer.answer_links.build
    respond_to do |format|
      format.js
    end
  end
end
