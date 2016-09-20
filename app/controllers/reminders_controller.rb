class RemindersController < ApplicationController

  load_and_authorize_resource

  def index
  end

  def new
    @deadlines = Deadline.all
  end

  def create
    if @reminder.save
      flash[:notice] = "Successfully added reminder."
      @reminder.associate_deadlines(params[:deadlines]) if params[:deadlines].present?
      respond_to do |format|
        format.html { redirect_to @reminder }
      end
    else
      redirect_to new_reminder_path(@reminder)
    end
  end

  def show
  end

  def edit
    @deadlines = Deadline.all
  end

  def update
    if @reminder.update_attributes(params[:reminder])
      flash[:notice] = "Successfully updated reminder."
      @reminder.update_associated_deadlines(params[:deadlines]) if params[:deadlines].present?
      respond_to do |format|
        format.html { redirect_to @reminder }
      end
    else
      redirect_to edit_reminder_path(@reminder)
    end
  end

  def destroy
    @reminder.destroy
    flash[:notice] = "Successfully removed reminder."
    respond_to do |format|
      format.html { redirect_to reminders_path }
    end
  end
end
