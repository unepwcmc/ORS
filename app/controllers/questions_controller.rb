class QuestionsController < ApplicationController

  authorize_resource

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = Question.find(params[:id], :include => :question_fields)
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @question }
      format.js
    end
  end

  # GET /questions/1/edit
  def edit
    @question = Question.find(params[:id], :include => [:answer_type, :question_fields])
    update_questionnaire_last_editor(@question.questionnaire, current_user)
    if @question.answer_type.is_a?(MultiAnswer) and not @question.answer_type.other_required?
      @question.question_fields.each do |qfield|
        @question.answer_type.other_fields.build(:language => qfield.language, :is_default_language => qfield.is_default_language)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    clean_answer_types_from params
    @question = Question.find(params[:id], :include => [:answers, {:answer_type => :answer_type_fields}, :question_fields])
    @question.update_answer_type params
    update_questionnaire_last_editor(@question.questionnaire, current_user)
    respond_to do |format|
      if @question.update_attributes(params[:part])
        flash[:notice] = 'Question was successfully updated.'
        format.html { redirect_to(@question) }
        format.js
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /questions/1/delete
  def delete
    @question = Question.find(params[:id], :include => :question_fields)
    questionnaire = @question.questionnaire
    if  @question.questionnaire.active?
      flash[:error] = "This question's questionnaire is active, and so you can not delete its questions."
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    end
    update_questionnaire_last_editor(questionnaire, current_user)
    respond_to do |format|
      format.html
      format.js
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question = Question.find(params[:id], :include => [ :question_fields])
    @questionnaire = @question.questionnaire
    if params[:cancel]
      redirect_to(dashboard_questionnaire_path(@questionnaire)) and return
    elsif  @questionnaire.active?
      flash[:error] = "This question's questionnaire is active, and so you can not delete its questions."
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    end
    @question.questionnaire_part.destroy
    @question.destroy
    update_questionnaire_last_editor(@questionnaire, current_user)
    respond_to do |format|
      flash[:notice] = "Question has been successfully deleted."
      format.html { redirect_to(questionnaire_path(@questionnaire)) }
      format.xml { head :ok }
    end
  end

  def preview
    @question = Question.find(params[:id], :include => [{:answer_type => :answer_type_fields}, :question_fields])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def dependency_options
    @answer_type = Question.find(params[:id], :include => [{:answer_type => [:answer_type_fields, :multi_answer_options]}]).answer_type
    respond_to do |format|
      format.js
    end
  end

  def answers
    question = Question.find(params[:id],
      :include => [ :answers,
      {:questionnaire_part => {:questionnaire => {:authorized_submitters => :user}}}])
    @users = question.questionnaire.submitters.
      all(:order => "(users.first_name || ' ' || users.last_name) ASC")
    if params[:looping_selection]
      looping_identifier = LoopItem.
        build_looping_identifier_for_responses_page params[:looping_selection]
      @answers = question.answers.
        find(:all,
         :conditions => ["answers.looping_identifier = ?", looping_identifier],
         :include => [:user, :answer_parts])
    else
      @answers = question.answers.all(:include => :user)
    end
    respond_to do |format|
      format.js
    end
  end
end
