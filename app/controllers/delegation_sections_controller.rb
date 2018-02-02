class DelegationSectionsController < ApplicationController

  authorize_resource

  def new
    @available_sections = []
    if params[:delegation_id]
      @delegation = Delegation.find(params[:delegation_id], :include => [ {:questionnaire => [ {:questionnaire_parts => :part} ]} , :user, :delegate, :delegation_sections] )
      @delegation_section = @delegation.delegation_sections.build
      @available_sections = @delegation.available_sections
    else
      user = current_user
      @section = Section.find(params[:section_id])
      authorization = user ? user.authorization_for(@section) : false
      raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !authorization || authorization[:error_message]
      @loop_item_name = nil
      if params[:loop_item_name_id].present?
        @loop_item_name = LoopItemName.find(params[:loop_item_name_id])
      end
      I18n.locale = authorization[:language]
      @existing_delegations = @section.delegations_from user
      @available_delegates = Delegation.delegates_not_yet_delegated(user, @section, @loop_item_name.try(:id))
      @delegations_whole_questionnaire = user.delegations.reject{ |d| d.delegation_sections.any? }
      unless @available_delegates.empty?
        @delegation_section = DelegationSection.new(:section_id => @section.id)
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @delegation_section = DelegationSection.create_delegation(params, current_user)
    if !@delegation_section
      delegation = Delegation.find(params[:delegation_id])
      flash[:error] = t('delegate_section.added_failure')
      redirect_to :action => "new", :delegation_id => delegation.id and return
    else
      @delegation_section.add_loop_item_names_from(params[:loop_item_names]) if params[:loop_item_names].present?
      flash[:notice] = t('delegate_section.added_success')
      UserMailer.section_delegated(@delegation_section, "http://#{request.host}").deliver
      @section = @delegation_section.section
    end
    respond_to do |format|
      format.html { redirect_to delegation_path(@delegation_section.delegation) }
      format.js { redirect_to new_delegation_section_path(:section_id => @section, :loop_item_name_id => params[:loop_item_name_id], :loop_item_names => params[:loop_item_names], :format => :js) }
    end
  end

  def edit
    @delegation_section = DelegationSection.find(params[:id], :include => [{:delegation => [:sections, :questionnaire]}, {:section => {:loop_item_type => :loop_item_names}}, :delegated_loop_item_names])
    @available_sections = @delegation_section.delegation.available_sections_including @delegation_section.section
  end

  def update
    @delegation_section = DelegationSection.find(params[:id], :include => :delegation)
    @delegation_section.update_attributes(params[:delegation_section])
    @delegation_section.update_loop_item_names_from(params[:loop_item_names]) if params[:loop_item_names].present?
    respond_to do |format|
      format.html { redirect_to delegation_path(@delegation_section.delegation) }
    end
  end

  def destroy
    @delegation_section = DelegationSection.find(params[:id])
    @delegation = @delegation_section.delegation
    @removed_id = @delegation_section.id
    @section = @delegation_section.section
    loop_item_names = @delegation_section.delegated_loop_item_names.map(&:loop_item_name_id)
    if @delegation.from_submission? && @delegation.delegation_sections.count == 1
      @user_delegate_id = @delegation.user_delegate_id
      @delegation.destroy
    else
      @delegation_section.destroy
    end
    flash[:notice] = t('delegate_section.removed_success')
    respond_to do |format|
      format.html {
        if @user_delegate_id.present?
          redirect_to user_delegate_path(@user_delegate_id)
        else
          redirect_to delegation_path(@delegation)
        end
      }
      format.js { render js: "location.reload()" }
    end
  end

end
