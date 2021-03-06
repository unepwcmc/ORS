class PasswordResetsController < ApplicationController
  #before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [ :edit, :update ]

  def new
    @email = params[:email]|| ''
  end

  def create
    @user = User.find_by_email(params[:email].downcase)
    if @user
      @user.deliver_password_reset_instructions!
      flash[:notice] = "Instructions to reset your password have been emailed to you"
      redirect_to root_path
    else
      flash.now[:error] = "No user was found with email address #{params[:email].downcase}"
      render :action => :new
    end
  end

  def edit
  end

  def update
    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    # Use @user.save_without_session_maintenance instead if you
    # don't want the user to be signed in automatically.
    if @user.save
      flash[:notice] = "Your password was successfully updated"
      @user.reset_perishable_token!
      redirect_to @user
    else
      if params[:password] != params[:password_confirmation]
        flash[:error] = "Password confirmation does not match"
      else
        flash[:error] = "Password is too short"
      end
      render :action => :edit
    end
  end


  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:error] = "We're sorry, but we could not locate your account"
      redirect_to root_url
    end
  end
end
