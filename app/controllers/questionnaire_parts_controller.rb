class QuestionnairePartsController < ApplicationController

  def new
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => [:loop_sources, :questionnaire_parts])
    @parent = params[:parent_id].present? ? QuestionnairePart.find(params[:parent_id], :include => :part) : nil
    if ( @parent && @parent.part.is_a?(Question) ) || ( !@parent && params[:part_type] == "Question" )
      flash[:error] = "Questions can't have descendants, and must be created under a section."
      redirect_to @questionnaire and return
    end
    @questionnaire_part = @parent ? QuestionnairePart.new(:parent_id => @parent.id) : @questionnaire.questionnaire_parts.new
    #get questionnaire's loop_sources
    @loop_sources = @questionnaire.loop_sources.present? ? @questionnaire.loop_sources : nil
    @questionnaire_part.build_part_from_params params, @questionnaire
    respond_to do |format|
      #format.html # new.html.erb
      format.js  { render "#{params[:part_type].underscore.pluralize}/new" }
    end
  end

  def create
    @questionnaire_part = QuestionnairePart.new(params[:questionnaire_part])
    clean_answer_types_from params
    @part = @questionnaire_part.part_type.classify.constantize.send("create_#{@questionnaire_part.part_type.underscore}_from", params)
    @questionnaire_part.part = @part
    respond_to do |format|
      if @part.save && @questionnaire_part.save
        flash[:notice] = "Successfully created questionnaire part."
        format.html { redirect_to @part }
        format.js { render "#{@questionnaire_part.part_type.underscore.pluralize}/create" }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  def part_can_be_moved
    @questionnaire_part = QuestionnairePart.find(params[:id])
    @result = @questionnaire_part.ancestors.map(&:part).delete_if{ |a| !a.loop_source_id.present? }.empty?
    respond_to do |format|
      format.js { render :js  => @result, :callback => params[:callback] }
    end
  end

  def node_move_information
    questionnaire_part = QuestionnairePart.find(params[:id], :include => [:part])
    @part = questionnaire_part.part
    respond_to do |format|
      format.js
    end
  end
end
