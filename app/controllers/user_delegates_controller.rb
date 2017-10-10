require 'securerandom'

class UserDelegatesController < ApplicationController

  before_filter :check_permissions, except: [:index, :delete, :dashboard]

  def index
    @user = User.find(params[:user_id], :include => :created_users)
    if !current_user.role?(:admin)
      if @user != current_user || (!@user.role?(:admin) && !@user.role?(:respondent))
        raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
      end
    end
    @user_delegates = @user.user_delegates
    @user_delegators = @user.user_delegators
  end

  def show
    @user_delegate = UserDelegate.find(params[:id], :include => :delegations)
  end

  def new
    @user = User.find(params[:user_id])
    @delegates = User.unassigned_delegates(@user)
    @user_delegate = @user.user_delegates.new
  end

  def create
    success = false
    @user_delegate = UserDelegate.new(params[:user_delegate])
    user = current_user.role?(:admin) ? User.find(params[:user_id]) : current_user
    @user_delegate.user = user
    if @user_delegate.delegate_id
      if UserDelegate.find_by_user_id_and_delegate_id(@user_delegate.user_id, @user_delegate.delegate_id)
        flash[:error] = t('user_delegates.already_a_delegate')
      elsif @user_delegate.save
        UserMailer.delegate_request(@user_delegate).deliver
      end
      success = true
    else
      delegate = User.find_by_email(params[:delegate_email])
      role = params["super_delegate"] == "false" ? Role.find_by_name("delegate") : Role.find_by_name("super_delegate")
      if delegate
        @user_delegate.delegate_id = delegate.id
        delegate.roles << role unless delegate.roles.include?(role)
        delegate.save
        if @user_delegate.save
          UserMailer.delegate_request(@user_delegate).deliver
          success = true
        elsif UserDelegate.find_by_user_id_and_delegate_id(@user_delegate.user_id, @user_delegate.delegate_id)
          flash[:error] = t('user_delegates.email_already_a_delegate')
          success = true
        end
      else
        password = SecureRandom.hex.first(8)
        delegate = User.new(:email => params[:delegate_email], :password => password, :password_confirmation => password,
        :language => (params[:delegate][:language] || "en"), :first_name => params[:delegate_first_name], :last_name => params[:delegate_last_name])
        delegate.roles << role
        if delegate.save
          @user_delegate.delegate_id = delegate.id
          if @user_delegate.save
            UserMailer.delegate_registration(delegate, password, "http://#{request.host}/").deliver
            success = true
          end
        end
      end
    end
    if success
      redirect_to user_user_delegates_path(user)
    else
      flash[:error] = delegate.errors.messages.map{ |key, value| "#{key} #{value}" }.join("<br/>")
      render :action => "new"
    end
  end

  def delete
  end

  def destroy
    current_user.user_delegates.destroy UserDelegate.find params[:id]
    respond_to do |format|
      flash[:notice] = "Delegate has been successfully deleted."
      format.html { redirect_to(user_user_delegates_path(current_user)) }
      format.xml { head :ok }
    end
  end

  def dashboard
    @delegate = User.find(params[:id], :include => [:delegated_tasks])
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if @delegate != current_user
    @delegated_tasks = @delegate.delegated_tasks.reject{ |d| d.questionnaire.nil? }
  end

  private

  def check_permissions
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || (!current_user.role?(:admin) && !current_user.role?(:respondent))
  end
end
