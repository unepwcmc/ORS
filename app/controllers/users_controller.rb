class UsersController < ApplicationController

  before_filter :find_with_questionnaires, :only => :update_submission_page
  load_and_authorize_resource :except => :destroy

  def index
    #@users = User.find(:all, :include => [:roles, :available_questionnaires])
    @groups = User.group_counts
  end

  def new
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if current_user
    #@user = User.new
  end

  def create
    #@user = User.new(params[:user])
    #@questionnaire is fetch to send to the user .new page form. So that if the user is being added through an authorized submitters
    # page, the correct fields needed for that questionnaire are present in the form
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => :questionnaire_fields) if params[:questionnaire_id]
    @user.roles << Role.find_by_name("respondent") unless @user.roles.any?
    if @user.save
      @user.add_or_update_filtering_fields(params[:filtering_field]) if params[:filtering_field]
      url = "http://#{request.host}/"
      if !current_user
        UserMailer.registration_confirmation(@user, url).deliver
        User.administrators.each do |admin|
          UserMailer
            .admin_notification_registration_confirmation(admin, @user)
            .deliver
        end
      else
        UserMailer
          .user_registration(@user, params[:user][:password], url)
          .deliver
      end
      respond_to do |format|
        format.html {
          if @user.creator_id == 0
            flash[:notice] = t('flash_messages.sign_up_success')
            redirect_to root_url
          else
            flash[:notice] = t('flash_messages.delegate_success')
            redirect_to user_user_delegates_path(current_user)
          end
        }
        format.js
      end
    else
      respond_to do |format|
        format.html { 
          render :action => "new", :params => {:lang => (params[:lang]||"en")}
        }
        format.js
      end
    end
  end

  def show
    #@user = User.find(params[:id], :include => [ { :available_questionnaires => [ :authorized_submitters, :questionnaire_fields] }])
  end

  def edit
    #@user = User.find(params[:id], :include => [:roles, { :available_questionnaires => [:questionnaire_fields ] }])
  end

  def update
    #@user = User.find(params[:id])
    update_authorizations = params[:user][:language] != @user.language
    if @user.update_attributes(params[:user])
      @user.update_authorizations if update_authorizations
      @user.add_or_update_filtering_fields(params[:filtering_field]) if params[:filtering_field]
      flash[:notice] = t('flash_messages.update_profile_s') 
      redirect_to @user
    else
      render :action => 'edit'
    end
  end

  def group
    ( params[:group] && !params[:group].blank? ) ? @group = params[:group] : @group = params[:groups]
    @users = User.add_users_to_group(params[:users], @group)
    if params[:users]
      @groups = User.group_counts
      @questionnaire = Questionnaire.find(params[:questionnaire_id]) if params[:questionnaire_id]
    end
    respond_to do |format|
      format.js
    end
  end

  def remove_group
    #@user = User.find(params[:id])
    params[:questionnaire_id] ? @users_index = false : @users_index = true
    @group = params[:group_name]
    @user.group_list.delete(@group)
    @user.save!
    #flash[:notice] = @user.first_name + " " + @user.last_name + " has been successfully removed from group " + params[:group_name] + "."
    respond_to do |format|
      format.js
    end
  end

  def delete
    @user = User.find(params[:id])
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || @user.role?(:admin)
  end

  def destroy
    @user = User.find(params[:id])
    raise CanCan::AccessDenied.new(t('flash_messages.not_authorized')) if !current_user || @user.role?(:admin)
    if params[:cancel]
      redirect_to users_path and return
    else
      @user.questionnaires.each do |questionnaire|
        questionnaire.user = current_user
        questionnaire.save
      end
      @user.destroy
      flash[:notice] = "User successfully deleted."
    end
    respond_to do |format|
      format.html{ redirect_to users_path }
    end
  end

  def update_submission_page
    @available_questionnaires = @user.available_questionnaires
    respond_to do |format|
      format.js
    end
  end

  def upload_list
    @status = {}
    @user = current_user
    url = "http://#{request.host}/"
    @user.parse_uploaded_list(params[:list_of_users].path, @status, url)
    if @status[:errors].present?
      flash[:error] = "There were some errors when parsing the file you provided."
    else
      flash[:notice] = "Successfully uploaded the list of users."
    end
  end

  private
  def find_with_questionnaires
    @user = User.find(params[:id], :include => [:available_questionnaires, :pdf_files])
  end
end

