class MatrixAnswersController < ApplicationController

  # GET /matrix_answers/new
  # GET /matrix_answers/new.xml
  def new
    @matrix_answer = MatrixAnswer.new
    @matrix_answer.matrix_answer_queries.build
    @matrix_answer.matrix_answer_options.build
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @matrix_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language )
        @matrix_answer.matrix_answer_queries.first.matrix_answer_query_fields.build(:language => field.language, :is_default_language => field.is_default_language)
        @matrix_answer.matrix_answer_options.first.matrix_answer_option_fields.build(:language => field.language, :is_default_language => field.is_default_language)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @matrix_answer = MatrixAnswer.find_or_initialize_by_id(params[:id]) #, :include => [:answer_type_fields, {:matrix_queries => :matrix_query_fields}, {:matrix_answer_options => :matrix_option_fields} ] )
    if @matrix_answer.new_record?
      @matrix_answer.matrix_answer_queries.build
      @matrix_answer.matrix_answer_options.build
    end
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    if @questionnaire
      @questionnaire.questionnaire_fields.each do |field|
        @matrix_answer.answer_type_fields.build(:language => field.language, :is_default_language => field.is_default_language ) unless @matrix_answer.answer_type_fields.find_by_language(field.language)
        @matrix_answer.matrix_answer_queries.each do |mar|
          mar.matrix_answer_query_fields.build(:language => field.language, :is_default_language => field.is_default_language) unless mar.matrix_answer_query_fields.find_by_language(field.language)
        end
        @matrix_answer.matrix_answer_options.each do |mac|
          mac.matrix_answer_option_fields.build(:language => field.language, :is_default_language => field.is_default_language) unless mac.matrix_answer_option_fields.find_by_language(field.language)
        end
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

end
