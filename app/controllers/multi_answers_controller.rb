class MultiAnswersController < ApplicationController

  def new
    @multi_answer = MultiAnswer.new
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @multi_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language )
        @multi_answer.other_fields.build(:language => field.language, :is_default_language => field.is_default_language)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @multi_answer = MultiAnswer.find_or_initialize_by_id(params[:id]) #, :include => [:answer_type_fields, {:multi_answer_options => :multi_answer_option_fields}, :other_fields])
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @multi_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language ) unless @multi_answer.answer_type_fields.find_by_language(field.language)
        @multi_answer.other_fields.build(:language => field.language, :is_default_language => field.is_default_language) unless @multi_answer.other_fields.find_by_language(field.language)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

end
