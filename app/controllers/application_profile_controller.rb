class ApplicationProfileController < ApplicationController

  authorize_resource

  def index
    @application_profile = first_or_new
  end

  def update
    @application_profile = first_or_new
    if @application_profile.update_attributes(params[:application_profile])
      flash[:notice] = "Profile updated"
    else
      flash[:error] = @application_profile.errors.messages.map{|key, value| value}.join("\n")
    end
    redirect_to application_profile_index_path
  end

  private

  def first_or_new
    ApplicationProfile.first || ApplicationProfile.new
  end
end
