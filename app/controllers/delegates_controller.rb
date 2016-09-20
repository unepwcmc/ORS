class DelegatesController < ApplicationController
  def index
    @user = User.find(params[:user_id], :include => :created_users)
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if @user != current_user || (!@user.role?(:admin) && !@user.role?(:respondent))
    @delegates = @user.delegates
  end

  def show
    @delegate = User.find(params[:id], :include => :delegated_tasks)
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || (!current_user.role?(:admin) && !current_user.role?(:respondent))
  end

  def new
    @user = User.find(params[:user_id], :include => :created_users)
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || (!current_user.role?(:admin) && !current_user.role?(:respondent))
    @delegate = @user.created_users.build(:creator_id => @user.id)
    render :template => "users/new"
  end

  def dashboard
    @delegate = User.find(params[:id], :include => [:delegated_tasks, :creator])
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if @delegate != current_user
    @delegated_tasks = @delegate.delegated_tasks
  end
end
