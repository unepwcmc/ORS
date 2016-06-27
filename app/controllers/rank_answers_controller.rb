class RankAnswersController < ApplicationController
  def new
    @rank_answer = RankAnswer.new
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @rank_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language )
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @rank_answer = RankAnswer.find_or_initialize_by_id(params[:id])#, :include => [:answer_type_fields, {:rank_answer_options => :rank_answer_option_fields}])
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @rank_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language ) unless @rank_answer.answer_type_fields.find_by_language(field.language)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end
end
