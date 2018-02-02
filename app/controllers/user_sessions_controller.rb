class UserSessionsController < ApplicationController
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      I18n.locale = @user_session.user.language
      flash[:notice] = t('flash_messages.logged_successfully')
      if @user_session.user.role?(:admin)
        redirect_to administration_path
      elsif @user_session.user.role?(:respondent_admin)
        redirect_to respondent_admin_path
      else
        redirect_to_target_or_default(root_url)
      end
    else
      flash[:notice] = "Username or password was incorrect"
      redirect_to root_url, :params => {:lang => params[:lang] || "en"}
    end
  end

  def destroy
    @user_session = UserSession.find
    @user_session.destroy if @user_session
    flash[:notice] = t('flash_messages.logged_out')
    redirect_to root_url
  end
end
