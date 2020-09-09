class QuestionnairesController < ApplicationController
  layout 'respondent', only: ['submission']

  before_filter :login_required, :only => [ :submission ]
  before_filter :fill_index, :only => :index
  before_filter :build_object_for_create, :only => :create
  before_filter :load_questionnaire_parts, :only => [:tree, :submission, :move_questionnaire_part, :jstree, :update_languages, :sections ]
  before_filter :load_questionnaire_fields, :only => [ :show, :edit, :update, :communication_details ]
  before_filter :set_last_editor, :only => [:activate, :deactivate, :open, :close, :update]
  before_filter :check_delegate_authorisation, :only => [:submission]
  load_and_authorize_resource

  # GET /questionnaires
  # GET /questionnaires.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @questionnaires }
    end
  end

  def dashboard
    @questionnaire = Questionnaire.find(params[:id], :include => [ {:questionnaire_parts => :part}, :questionnaire_fields, :user, :authorized_submitters, {:loop_sources => :loop_item_type} ])
    respond_to do |format|
      format.html
    end
  end

  # GET /questionnaires/1
  # GET /questionnaires/1.xml
  def show
    #@questionnaire = Questionnaire.find(params[:id], :include => [:questionnaire_fields ])
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @questionnaire }
      format.js
    end
  end

  # GET /questionnaires/new
  # GET /questionnaires/new.xml
  def new
    @questionnaire = Questionnaire.new(:questionnaire_date => Date.today)
    @questionnaires_created = Questionnaire.last_created(10)
    @questionnaire.build_questionnaire_fields!
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @questionnaire }
    end
  end

  # POST /questionnaires
  # POST /questionnaires.xml
  def create
    if params[:questionnaire][:original_id]
      flash[:notice] = "Questionnaire duplication is underway, you will receive an email when it is finished."
      redirect_to questionnaires_path
    else
      @questionnaire.last_editor = current_user
      @questionnaire.user = current_user
      respond_to do |format|
        if @questionnaire.save
          flash[:notice] = 'Questionnaire was successfully created.'
          format.html { redirect_to(@questionnaire) }
          format.js  { render :layout => false }
        else
          #fill variables need to the new.html.erb page
          @questionnaires_created = Questionnaire.last_created(10)
          @questionnaire.build_questionnaire_fields!
          format.html { render :action => "new" }
          format.js
        end
      end
    end
  end

  # GET /questionnaires/1/edit
  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  def communication_details
    respond_to do |format|
      format.html
    end
  end

  # PUT /questionnaires/1
  # PUT /questionnaires/1.xml
  def update
    @questionnaire.last_editor = current_user
    respond_to do |format|
      if @questionnaire.update_attributes(params[:questionnaire])
        flash[:notice] = 'Questionnaire was successfully updated.'
        format.html { redirect_to(@questionnaire) }
        format.js
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def manage_languages
    @questionnaire.build_questionnaire_fields!
  end

  def update_languages
    old_languages = @questionnaire.questionnaire_fields.map{ |a| a.language }
    old_default = @questionnaire.questionnaire_fields.find_by_is_default_language(true).language
    if @questionnaire.update_attributes(params[:questionnaire])
      @questionnaire.propagate_languages_changes(old_languages, old_default)
      flash[:notice] = "Successfully updated questionnaire's languages"
      @success = true
    else
      @success = false
      flash[:error] = "There was a problem updating the questionnaire's languages"
    end
    respond_to do |format|
      format.html { redirect_to dashboard_questionnaire_path(@questionnaire) }
      format.js
    end
  end

  # GET /questionnaires/1/delete
  def delete
    if @questionnaire.user != current_user
      raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
    elsif @questionnaire.active?
      flash[:error] = "The questionnaire is active, and so it can not be deleted."
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  # DELETE /questionnaires/1
  # DELETE /questionnaires/1.xml
  def destroy
    if @questionnaire.user != current_user
      raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
    elsif  @questionnaire.active?
      flash[:error] = "The questionnaire is active, and so it can not be delete."
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    elsif params[:cancel]
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    end
    @questionnaire.destroy_all_questionnaire_elements!
    @questionnaire.destroy
    flash[:notice] = "Questionnaire and components have been successfully deleted."
    respond_to do |format|
      format.html { redirect_to questionnaires_path }
      format.xml { head :ok }
    end
  end

  #Preview Questionnaire
  def preview
    @questionnaire = Questionnaire.find(params[:id], :include => [:questionnaire_fields, {:questionnaire_parts => :part}, {:loop_sources => {:loop_item_type => [:loop_items]}}])
    respond_to do |format|
      format.html
      format.js
    end
  end

  #Activate Questionnaire
  def activate
    @errors = nil
    #@questionnaire = Questionnaire.find(params[:id])
    if @questionnaire.activate!
      flash[:notice] = "Questionnaire successfully activated."
    else
      @errors = "Questionnaire is closed, cannot be activated."
      flash[:error] = "Errors when activating the questionnaire. You can not activate a questionnaire that is closed or already active."
    end
    respond_to do |format|
      format.html { redirect_to(dashboard_questionnaire_path(@questionnaire)) }
      format.js
    end
  end

  #Deactivate Questionnaire
  def deactivate
    @errors = false
    if @questionnaire.deactivate!
      flash[:notice] = "Questionnaire successfully deactivated."
    else
      @errors = true
      flash[:error] = "Errors deactivating the questionnaire."
    end
    respond_to do |format|
      format.html { redirect_to(dashboard_questionnaire_path(@questionnaire)) }
      format.js
    end
  end

  #Sets the status of a questionnaire to close. This prevents respondents
  #from being able to access the questionnaire's submission page
  def close
    @result = @questionnaire.close!
    if @result
      flash[:notice] = "Questionnaire successfully closed!"
    else
      flash[:error] = "Errors when closing questionnaire. You can only close a questionnaire that is active."
    end
    respond_to do |format|
      format.html { redirect_to(dashboard_questionnaire_path(@questionnaire)) }
      format.js
    end
  end

  #Changes the status of a questionnaire to open so that it is available
  #for respondents to fill in answers
  def open
    @result = @questionnaire.open!
    if @result
      flash[:notice] = "Questionnaire successfully opened."
    else
      flash[:error] = "Errors when closing questionnaire. You can only open a questionnaire that is closed."
    end
    respond_to do |format|
      format.html { redirect_to(dashboard_questionnaire_path(@questionnaire)) }
      format.js
    end
  end

  #Access questionnaire to fill in answers as a respondent
  def submission
    if current_user.is_admin_or_respondent_admin? && params[:respondent_id]
      @respondent = User.find(params[:respondent_id])
      @authorization = @respondent ? @respondent.authorization_for(@questionnaire, nil, @respondent.id) : false
    else
      @authorization = current_user ? current_user.authorization_for(@questionnaire) : false
    end
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}"), :submission, Questionnaire) if !@authorization || @authorization[:error_message]
    if current_user.is_delegate?
      @delegation = current_user.delegated_tasks.find_by_questionnaire_id(@questionnaire.id)
    end
    @sections_to_display_in_tab = @questionnaire.sections_to_display_in_tab.
      includes(
        {loop_item_type: {loop_items: {loop_item_name: :loop_item_name_fields}}},
        :submission_states
      )
    @sections_to_display_in_tab_loops_expanded = []
    @sections_to_display_in_tab.each do |section|
      if section.looping? && section.loop_item_type
        section.loop_item_type.loop_items.each do |loop_item|
          if section.available_for?(@respondent || current_user, loop_item)
            submission_state = section.submission_states.find do |s|
              s.user_id == @authorization[:user].id && s.loop_item_id == loop_item.id
            end
            @sections_to_display_in_tab_loops_expanded << [section, loop_item, submission_state.try(:section_state) || SubmissionStatus::DEFAULT]
          end
        end
      else
        submission_state = section.submission_states.find do |s|
          s.user_id == @authorization[:user].id
        end
        @sections_to_display_in_tab_loops_expanded << [section, nil, submission_state.try(:section_state) || SubmissionStatus::DEFAULT]
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def submit
    #submit questionnaire on behalf of respondent if admin
    respondent = User.find(params[:respondent_id]) if params[:respondent_id]
    if respondent && !current_user.admin_can_submit_questionnaire?(respondent)
      flash[:error] = t('flash_messages.not_authorized')
      redirect_to submission_questionnaire_path(@questionnaire)
      return
    end
    user = respondent || current_user
    #check if mandatory questions were answered
    @authorized_submitter = AuthorizedSubmitter.find_by_questionnaire_id_and_user_id(@questionnaire.id, user.id)
    if user.submission_states.find(:all, conditions: {section_id: @questionnaire.sections.map(&:self_and_descendants).
                                           flatten.map(&:id), section_state: 1, dont_care: false}).empty? &&
                                           @authorized_submitter
      @authorized_submitter.status = SubmissionStatus::SUBMITTED
      if @authorized_submitter.save!
        if Rails.env == 'production'
          UserMailer.questionnaire_submitted(current_user, @questionnaire).deliver
          UserMailer.admin_notification_questionnaire_submitted(current_user, @questionnaire).deliver
        end
      end
      flash[:notice] = t('s_details.submission_success') if !flash[:error]
      redirect_to user_path(current_user)
    else
      flash[:error] = t('s_details.submission_failure')
      redirect_to submission_questionnaire_path(@questionnaire, respondent_id: params[:respondent_id])
    end
  end

  def unsubmit
    @questionnaire = Questionnaire.find(params[:id])
    @authorized_submitter = AuthorizedSubmitter.find_by_questionnaire_id_and_user_id(@questionnaire.id, params[:user_id])
    @authorized_submitter.status = SubmissionStatus::UNDERWAY
    @authorized_submitter.requested_unsubmission = false
    @authorized_submitter.save!
    flash[:notice] = "The questionnaire is again open for editing."
    redirect_to respondents_questionnaire_path(@questionnaire)
  end

  def tree
    @obj = @questionnaire.questionnaire_structure(params)
    respond_to do |format|
      format.js { render :json => @obj.to_json, :callback => params[:callback] }
    end
  end

  def respondents
    @questionnaire = Questionnaire.find(params[:id], :include => [:questionnaire_fields, :user, :authorized_submitters])
    #@the_url = "http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")
    respond_to do |format|
      format.html
    end
  end

  def duplicate
    # Temporarily disable questionnaire duplication for
    # questionnaires which have already been created from another one.
    @questionnaires = Questionnaire.includes(:questionnaire_fields, :user, :questionnaire_parts).where(original_id: nil)
    @questionnaire = Questionnaire.new
    respond_to do |format|
      format.html
    end
  end

  def to_pdf
    @user = params[:user].present? ? User.find(params[:user]) : current_user
    preview = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:preview])
    if !preview
      flash[:notice] = "File is being generated. An email will be sent to you when it is ready for download from this page. Note that generating the file can take some minutes."
      url_prefix = "http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")
      generating_place_holder = "#{Rails.root}/private/questionnaires/#{@questionnaire.id}/users/#{@user.id}/generating_#{params[:is_short] ? "short" : "long"}_pdf"
      if !File.directory? generating_place_holder
        FileUtils.mkdir_p(generating_place_holder)
      end
      PdfGenerator.perform_async(current_user.id, @user.id, @questionnaire.id, url_prefix, (params[:is_short] == "true"))
      #QuestionnairePdf.new.to_pdf(current_user, @user, @questionnaire, url_prefix, (params[:is_short]=="true"))
    else
      output = QuestionnairePdf.new.preview_pdf @questionnaire
    end

    if output
      send_data output, :filename => @questionnaire.title[0,35] +".pdf", :type => "application/pdf"
    end
  end

  def download_user_pdf
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    user = User.find(params[:user_id])
    pdf_file = @questionnaire.pdf_files.find_by_user_id_and_is_long(user, !params[:is_short])
    if pdf_file.present? && File.exist?(pdf_file.location)
      send_file pdf_file.location, :type => "pdf"
    end
  end

  def to_csv
    @questionnaire = Questionnaire.find(params[:id])
    separator = params[:separator]
    if @questionnaire
      #Convert Questionnaire's submission side and existing answers to csv
      # default location: private/questionnaires/questionnaire_id/
      QuestionnaireToCsv.perform_async(current_user.id, @questionnaire.id, separator)
      flash[:notice] = "File is being generated. An email will be sent to you when it is ready for download from this page. Note that generating the file can take some minutes."
    end
    respond_to do |format|
      format.js
    end
  end

  def empty_text_answers_report
    filename = 'empty_text_answers_report.csv'
    send_data Answer.empty_text_answers_to_csv, filename: filename, type: "text/csv"
  end

  def download_csv
    if @questionnaire.csv_file.present? && File.exist?(@questionnaire.csv_file.location)
      send_file @questionnaire.csv_file.location, :type => "csv"
    else
      flash[:error] = "It was not possible to download the requested file. Please generate the file again. Thank you."
      redirect_to questionnaires_path
    end
  end

  def generate_pivot_tables
    PivotTables::Generator.new(@questionnaire).run
    flash[:notice] = "Pivot Table has been generated."
    respond_to do |format|
      format.js { render inline: 'location.reload();' }
    end
  end

  def download_pivot_tables
    if PivotTables.available_for_download?(@questionnaire)
      send_file PivotTables.last_generated_file_path(@questionnaire), type: 'xls'
    else
      flash[:error] = "It was not possible to download the requested file. Please generate the file again. Thank you."
      redirect_to questionnaires_path
    end
  end

  def send_deadline_warning
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    user = User.find(params[:user_id])
    url = "http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")
    UserMailer.questionnaire_due_warning(user, @questionnaire, Time.now, url).deliver
    flash[:notice] = "The requested e-mail has been sent."
    respond_to do |format|
      format.js
    end
  end

  def send_multiple_deadline_warnings
    if params[:users].present?
      params[:users].each do |user_id, |
        user = User.find(user_id)
        if user
          subject = params["subject_#{user.language}"].present? ? params["subject_#{user.language}"] : params["subject_#{@questionnaire.language}"]
          body = params["body_#{user.language}"].present? ? params["body_#{user.language}"] : params["body_#{@questionnaire.language}"]
          UserMailer.contact_questionnaire_users(user, subject, body).deliver
        end
      end
      flash[:notice] = "The requested emails have been sent."
    else
      flash[:error] = "Please select at least one user."
    end
    respond_to do |format|
      format.js { render "questionnaires/send_deadline_warning" }
    end
  end

  def structure_ordering
    #@questionnaire = Questionnaire.find(params[:id])
  end

  def move_questionnaire_part
    @questionnaire.move_the_questionnaire_part(params)
    render :nothing => true
  end

  #get the questionnaire tree
  def jstree
    @obj = @questionnaire.questionnaire_structure_for_js_tree(params)
    respond_to do |format|
      format.js { render :json => @obj.to_json, :callback => params[:callback] }
    end
  end

  def search
    @questionnaires = Questionnaire.all(
      :include => [:questionnaire_fields, {:questionnaire_parts => :part}],
      :order => 'questionnaires.created_at DESC')
  end

  def sections
    @sections = @questionnaire.sections.map(&:self_and_descendants).flatten
    respond_to do |format|
      format.js
    end
  end

  private

  def load_questionnaire_fields
    @questionnaire = Questionnaire.find(params[:id], :include => :questionnaire_fields)
  end

  def load_questionnaire_parts
    @questionnaire = Questionnaire.find(params[:id], :include => [:questionnaire_fields, {:questionnaire_parts => :part}])
  end

  def build_object_for_create
    if !params[:questionnaire][:original_id]
      @questionnaire = Questionnaire.new(params[:questionnaire])
    else
      #questionnaire_source.cloning current_user, ("http://" + request.host + (ActionController::Base.relative_url_root.present? ? ActionController::Base.relative_url_root : "")), params[:copy_answers]

      CloneQuestionnaire.perform_async(
        current_user.id,
        params[:questionnaire][:original_id],
        ("http://" + request.host +
          (ActionController::Base.relative_url_root
            .present? ? ActionController::Base.relative_url_root : "")),
        params[:copy_answers]
      )
    end
  end

  def fill_index
    if params[:order]
      @questionnaires = Questionnaire.find(:all, :order => "#{params[:order]} DESC", :include => [:questionnaire_fields, :user, :csv_file])
    elsif params[:active]
      @questionnaires = Questionnaire.where(status: QuestionnaireStatus::ACTIVE).order("created_at DESC")
    else
      @questionnaires = Questionnaire.order("created_at DESC").find(:all, :include => [:questionnaire_fields, :user, :csv_file])
    end
  end

  def set_last_editor
    @questionnaire = Questionnaire.find(params[:id])
    @questionnaire.last_editor_id = current_user.id
  end

  def check_delegate_authorisation
    if params[:user_delegate] && ( !UserDelegate.find_by_id(params[:user_delegate]) || !current_user.authorized_to_answer?(@questionnaire, params[:user_delegate]) )
      raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
    end
  end
end
