class TextAnswersController < ApplicationController

  def new
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    @text_answer = TextAnswer.new
    @text_answer.text_answer_fields.build
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @text_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language )
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def edit
    @text_answer = TextAnswer.find_or_initialize_by_id(params[:id]) #, :include => :answer_type_fields)
    if @text_answer.new_record?
      @text_answer.text_answer_fields.build
    end
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @text_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language ) unless @text_answer.answer_type_fields.find_by_language(field.language)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end
end
