class UserSessionsController < ApplicationController
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      I18n.locale = @user_session.user.language
      flash[:notice] = t('flash_messages.logged_successfully')
      redirect_to_target_or_default(root_url)
    else
      render :action => 'new', :params => {:lang => params[:lang] || "en"}
    end
  end

  def destroy
    @user_session = UserSession.find
    @user_session.destroy if @user_session
    flash[:notice] = t('flash_messages.logged_out')
    redirect_to root_url
  end
end
