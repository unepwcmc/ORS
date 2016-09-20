class DeadlinesController < ApplicationController

  before_filter :find_questionnaire, :only => [:index, :new, :create]
  load_and_authorize_resource

  def index
    @deadlines = @questionnaire.deadlines
  end

  def new
    @deadline = @questionnaire.deadlines.build
  end

  def create
    @deadline = @questionnaire.deadlines.build(params[:deadline])
    if @deadline.save
      flash[:notice] = "Successfully added deadline to the questionnaire."
    end
    respond_to do |format|
      format.html { redirect_to @deadline }
    end
  end

  def show
    @questionnaire = @deadline.questionnaire
  end

  def edit
    @questionnaire = @deadline.questionnaire
  end

  def update
    @deadline.update_attributes(params[:deadline])
    flash[:notice] = "Successfully updated deadline."
    respond_to do |format|
      format.html { redirect_to @deadline }
    end
  end

  def destroy
    @questionnaire = @deadline.questionnaire
    @deadline.destroy
    flash[:notice] = "Successfully removed deadline."
    respond_to do |format|
      format.html { redirect_to questionnaire_deadlines_path(@questionnaire) }
    end
  end

  private

  def find_questionnaire
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => [:questionnaire_fields, :deadlines])
  end
end
