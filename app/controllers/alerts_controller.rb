class AlertsController < ApplicationController

  before_filter :find_deadline, :only => [:new, :create]
  load_and_authorize_resource

  def new
    @alert = @deadline.alerts.build
    @reminders = Reminder.all - @deadline.reminders
  end

  def create
    reminder = Reminder.find(params[:alert][:reminder_id])
    if @deadline && reminder
      @alert = Alert.create(:reminder => reminder, :deadline => @deadline)
      flash[:notice] = "Successfully associated reminder with deadline."
      respond_to do |format|
        format.html { redirect_to @deadline }
      end
    else
      flash[:error] = "Something went wrong when associating the reminder with the deadline."
      redirect_to new_deadline_alert_path(@deadline)
    end
  end

  def destroy
    @deadline = @alert.deadline
    @alert.destroy
    respond_to do |format|
      format.html { redirect_to @deadline }
    end
  end

  private
  def find_deadline
    @deadline = Deadline.find(params[:deadline_id])
  end
end
