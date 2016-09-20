class DelegationsController < ApplicationController

  authorize_resource

  def show
    @delegation = Delegation.find(params[:id], :include => [:delegate, :user, :questionnaire])
    @delegator = @delegation.user
    @delegate = @delegation.delegate
  end

  def new
    @user_delegate = UserDelegate.find(params[:user_delegate_id], :include => {:user => :available_questionnaires})
    @delegator = @user_delegate.user
    @delegation = @delegator.delegations.build(:user_delegate_id => @user_delegate.id)
    @available_questionnaires = @delegator.available_questionnaires
  end

  def create
    @user_delegate = UserDelegate.find(params[:user_delegate_id], :include => [:user, :delegate])
    delegate = @user_delegate.delegate
    delegator = @user_delegate.user
    @delegation = Delegation.new(params[:delegation])
    if @delegation.save
      UserMailer.questionnaire_delegated(delegate, delegator, @delegation, "http://#{request.host}/").deliver
      flash[:notice] = "Task successfully delegated."
    else
      flash[:error] = "It was not possible to delegate the task."
    end
    respond_to do |format|
      format.html { redirect_to user_delegate_path(@user_delegate) }
    end
  end

  def edit
    @delegation = Delegation.find(params[:id])
    @delegator = @delegation.user
    @user_delegate = @delegation.user_delegate
    @available_questionnaires = @delegator.available_questionnaires
  end

  def update
    @delegation = Delegation.find(params[:id])
    @delegator = @delegation.user
    @user_delegate = @delegation.user_delegate
    @available_questionnaires = @delegator.available_questionnaires

    if @delegation.update_attributes(params[:delegation])
      flash[:notice] = "Delegation successfully updated"
    else
      flash[:error] = "It was not possible to update this delegation"
    end
    respond_to do |format|
      format.html { redirect_to user_delegate_path(@user_delegate) }
    end
  end

  def destroy
    @section = Section.find(params[:section_id]) if params[:section_id]
    @delegation = Delegation.find(params[:id])
    @user_delegate = @delegation.user_delegate
    @delegation.destroy
    respond_to do |format|
      format.html { redirect_to user_delegate_path(@user_delegate) }
      format.js { redirect_to new_delegation_section_path(:section_id => @section, :loop_item_name_id => params[:loop_item_name_id], :format => :js) }
    end
  end
end
