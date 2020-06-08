class AnswersController < ApplicationController

  before_filter :set_current_user_delegate

  def update
    @answer = Answer.find(params[:id])
    @authorization = current_user ? current_user.authorization_for(@answer.question, @current_user_delegate.try(:id)) : false
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
      error = @answer.errors.first #array[0] -> type, array[1] -> desc
      message = if error[0].match(/doc_file_size/).present?
                  # Improve paperclip's standard error message to show size in MB
                  size = error[1].match(/\d+/).to_s.to_i / 1000000
                  t('flash_messages.file_too_large', size: size)
                else
                  "There was a problem when saving your changes, please try again."
                end
      flash[:error] = message
      @success = false
    end
    respond_to do |format|
      format.js { render params[:to_render] }
    end
  end

  def add_document
    @question = Question.find(params[:id])
    @authorization = current_user ? current_user.authorization_for(@question, @current_user_delegate.try(:id)) : false
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    I18n.locale = @authorization[:language]
    user_id = params[:respondent_id].presence || @authorization[:user].id
    from_dependent_section, _ = @question.nested_under_dependent_section?
    # Use custom find_or_create method to make sure to fetch the correct answer and
    # not create new ones
    @answer = Answer.find_or_create_new_answer(@question, User.find(user_id), @question.section.root.questionnaire, from_dependent_section, params[:looping_identifier])
    @answer.documents.build
    respond_to do |format|
      format.js
    end
  end

  def add_links
    @question = Question.find(params[:id])
    @authorization = current_user ? current_user.authorization_for(@question, @current_user_delegate.try(:id)) : false
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    I18n.locale = @authorization[:language]
    user_id = params[:respondent_id].presence || @authorization[:user].id
    from_dependent_section, _ = @question.nested_under_dependent_section?
    # Use custom find_or_create method to make sure to fetch the correct answer and
    # not create new ones
    @answer = Answer.find_or_create_new_answer(@question, User.find(user_id), @question.section.root.questionnaire, from_dependent_section, params[:looping_identifier])
    @answer.answer_links.build
    respond_to do |format|
      format.js
    end
  end
end
