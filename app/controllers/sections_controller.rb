class SectionsController < ApplicationController

  authorize_resource

  before_filter :set_current_user_delegate, only: [:submission, :save_answers, :load_lazy]

  # GET /sections/1
  # GET /sections/1.xml
  def show
    @section = Section.find(params[:id], :include => [:section_fields, :answer_type, :questionnaire_part] )
    respond_to do |format|
      format.html # show.html.erb
      format.js
    end
  end

  # GET /sections/1/edit
  def edit
    @section = Section.find(params[:id], :include => [ :questionnaire_part, :section_fields, :answer_type ])
    @loop_sources = nil
    @loop_sources = @section.questionnaire.loop_sources if @section.questionnaire.loop_sources.present?
    questionnaire = @section.questionnaire
    update_questionnaire_last_editor(questionnaire, current_user)
    respond_to do |format|
      format.html
      format.js
    end
  end

  # POST /sections
  # POST /sections.xml
  def create
    @section = Section.create_section_from(params)
    respond_to do |format|
      if @section.save
        update_questionnaire_last_editor(@section.questionnaire, current_user)
        flash[:notice] = 'Section was successfully created.'
        format.html { redirect_to(@section) }
        format.js
      else
        #fetch the necessary data to present the new form filled and with the correct error messages.
        @questionnaire = Questionnaire.find(params[:section][:questionnaire_id], :include => :questionnaire_fields) if params[:section][:questionnaire_id]
        @parent = Section.find(params[:section][:parent_id]) if params[:section][:parent_id]
        @loop_sources = nil
        @loop_sources = @questionnaire ? ( @questionnaire.loop_sources if @questionnaire.loop_sources) : ( @parent.root.questionnaire.loop_sources if @parent.root.questionnaire.loop_sources )
        format.html { render :action => "new" }
        format.js
      end
    end
  end

  # PUT /sections/1
  # PUT /sections/1.xml
  def update
    clean_answer_types_from params
    @section = Section.section_update_from(params)
    params[:part][:answer_type_type] = "" unless params[:answer_type]
    respond_to do |format|
      if @section.update_attributes(params[:part])
        update_questionnaire_last_editor(@section.questionnaire, current_user)
        flash[:notice] = 'Section was successfully updated.'
        format.html { redirect_to(@section) }
        format.js
      else
        format.html { render :action => "edit" }
        format.js { render :layout => false }
      end
    end
  end

  # GET /sections/1/delete
  def delete
    @section = Section.find(params[:id], :include => :questionnaire_part)
    questionnaire = @section.questionnaire
    if !current_user.role? :admin
      raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
    elsif  @section.questionnaire.active?
      flash[:error] = "This section's questionnaire is active, and so you can not delete its sections."
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    end
    update_questionnaire_last_editor(questionnaire, current_user)
    respond_to do |format|
      format.html
      format.js
    end
  end

  # DELETE /sections/1
  # DELETE /sections/1.xml
  def destroy
    @section = Section.find(params[:id], :include => :questionnaire_part)
    @questionnaire = @section.questionnaire
    if params[:cancel]
      redirect_to(dashboard_questionnaire_path(@questionnaire)) and return
    elsif !current_user.role? :admin
      raise CanCan::AccessDenied.new(t('flash_messages.not_authorized'))
    elsif  @questionnaire.active?
      flash[:error] = "This section's questionnaire is active, and so you can not delete its sections."
      redirect_to dashboard_questionnaire_path(@questionnaire) and return
    end
    @section.delete_branch_questions!
    #@section.questionnaire_part.destroy
    update_questionnaire_last_editor(@questionnaire, current_user)
    respond_to do |format|
      flash[:notice] = "Section and descendants successfully removed!"
      format.html { redirect_to(questionnaire_path(@questionnaire)) }
      format.js { render :layout => false }
    end
  end

  # => action to show preview of the section
  def preview
    @section = Section.find(params[:id], :include => [ {:questions => :answer_type}, :questionnaire_part ])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def define_dependency
    @section = Section.find(params[:id])
    @all_sections = @section.questionnaire.sections.map(&:self_and_descendants).flatten
    respond_to do |format|
      format.html
      format.js
    end
  end

  def set_dependency
    @section = Section.find(params[:id])
    @section.depends_on_question_id = params[:section][:depends_on_question] if Question.find(params[:section][:depends_on_question])
    @section.depends_on_option_id = params[:section][:depends_on_option] if MultiAnswerOption.find(params[:section][:depends_on_option])
    @section.depends_on_option_value = params[:section][:depends_on_option_value] == "0" ? false : true
    if @section.save!
      respond_to do |format|
        format.html {
          flash[:notice] = "Dependency created."
          redirect_to section_path(params[:id])
        }
        format.js
      end
    end
  end

  def unset_dependency
    @section = Section.find(params[:id])
    @section.depends_on_option_id = @section.depends_on_option_value = @section.depends_on_question_id = nil
    if @section.save!
      respond_to do |format|
        format.html {
          flash[:notice] = "Dependency deleted."
          redirect_to section_path(params[:id])
        }
        format.js
      end
    end
  end

  def questions_for_dependency
    target_section = Section.find(params[:section_id])
    section = Section.find(params[:id], :include => [{:questions => [{:answer_type => :answer_type_fields}, :question_fields]}])
    @questions = target_section.available_questions_for_dependency_from section
    authorize! :questions, @section
    respond_to do |format|
      format.js
    end
  end

  def questions
    @section = Section.find(params[:id],
        :include => [ :questions, {:loop_item_type => {:loop_item_names => :loop_item_name_fields}}])
    @questions = @section.questions
    respond_to do |format|
      format.js
    end
  end

  def submission
    @section = Section.find(params[:id], :include => [{:questions => [:answer_type, :loop_item_types]}])
    load_authorization(@section, @current_user_delegate)
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    I18n.locale = @authorization[:language]
    @fields = {}
    @section.objects_fields_in(@authorization[:language], @fields)
    @fields[:answers] = @section.section_and_descendants_answers_for(@authorization[:user])
    @fields[:loop_item] = params[:loop_item_id] ? LoopItem.find(params[:loop_item_id]) : nil
    is_disabled = !( !@authorization[:is_closed] && ( !@authorization[:sections] || @authorization[:sections].has_key?(@section.id.to_s) ) )
    render :partial => "sections/submission", :locals => {:root => true, :loop_sources => @fields[:loop_item] ? {@fields[:loop_item].loop_item_type.root.loop_source.id.to_s => @fields[:loop_item]} : {}, :disabled => is_disabled}
  end

  def load_lazy
    @section = Section.find(params[:id], :include => [{:questions => [:answer_type , :question_fields]}])
    load_authorization(@section)
    raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
    I18n.locale = @authorization[:language]
    @fields = {}
    @details = Section.fill_lazy_load_details(params)
    @section.objects_fields_in(@authorization[:language], @fields)
    @fields[:answers] = @section.section_and_descendants_answers_for(@authorization[:user])
    @details[:container_id] = @section.id.to_s + "_" + (params[:looping_identifier].presence||"0")
    @fields[:disabled] = !( !@authorization[:is_closed] && ( !@authorization[:sections] || ( (@authorization[:sections].has_key?(@section.id.to_s) && @authorization[:sections][@section.id.to_s].empty?) || (@authorization[:sections].has_key?(@section.id.to_s) && @authorization[:sections][@section.id.to_s].include?((@details[:loop_item] ? @details[:loop_item].loop_item_name.id : '-1')) )) || !@details[:disabled] ) )
    respond_to do |format|
      format.js
    end
  end

  def save_answers
    if params[:auto_save] == "0" && params[:timed_save] == "0" && params[:save_from_button] == "0"
      respond_to do |format|
        format.html do
          render :nothing => true, :status => :ok
          return true
        end
        format.js  do
          render :nothing => true, :status => :ok
          return true
        end
      end
    else
      @result = {}
      @result[:section] = Section.find(params[:section])
      load_authorization(@result[:section], @current_user_delegate)
      raise CanCan::AccessDenied.new(t("flash_messages.#{@authorization ? @authorization[:error_message] : "not_authorized"}")) if !@authorization || @authorization[:error_message]
      I18n.locale = @authorization[:language]
      if params[:answers].present?
        @result[:result], @result[:questions_saved], @result[:fields_to_clear], @result[:auth_error] = Answer.save_answers(@result[:section].questionnaire, @authorization[:user], current_user, params[:answers], params[:hidden])
      else
        @result[:result] = false
      end
      if @result[:auth_error]
        flash[:error] = "Not authorized to edit respondent's answer"
      end
      if @result[:result]
        @result[:section].update_root_submission_state!(@authorization[:user], (@result[:root_loop_item].present? ? @result[:root_loop_item] : nil))
        flash[:notice] = "#{@result[:section].value_in((@result[:section].root? ? :tab_title : :title), @authorization[:language], @result[:root_loop_item])}: #{t("flash_messages.saved_successfully", {:locale => @authorization[:language]})}".squish
      elsif params[:auto_save] != "1" && params[:timed_save] != "1"
        flash[:notice] = t("flash_messages.nothing_to_save", {:locale => @authorization[:language]})
      end
      save_delegate_text_answers
      mark_as_answered
      respond_to  do |format|
        format.html do
          render :nothing => true, :status => :ok
          return true
        end
        format.js
      end
    end
  end

  #Get all the loop item names of the section, if it is a looping section
  #to create a delegation (delegates/new.html.erb)
  def loop_item_names
    @section = Section.find(params[:id])
    authorize! :questions, @section
    @item_names = @section.loop_item_names if @section && @section.looping?  && @section.loop_item_type.present?
    respond_to do |format|
      format.js { render :json => (@item_names ? @item_names.to_json : nil), :callback => params[:callback] }
    end
  end

  def to_csv
    @section = Section.find(params[:id])
    separator = params[:separator]
    if @section
      #@section.to_csv(current_user) #automatically delayed
      SectionToCsv.perform_async(current_user.id, @section.id, separator)
      flash[:notice] = "File is being generated. An email will be sent to you when it is ready for download from this page. Note that generating the file can take some minutes."
    end
    respond_to do |format|
      format.js
    end
  end

  def download_csv
    @section = Section.find(params[:id])
    if @section.csv_file.present? && File.exist?(@section.csv_file.location)
      send_file @section.csv_file.location, :type => "csv"
    else
      flash[:error] = "It was not possible to download the requested file. Please generate the file again. Thank you."
      redirect_to questionnaires_path
    end
  end

  private

  def save_delegate_text_answers
    return unless params[:delegate_text_answers]

    params[:delegate_text_answers].each do |unique_id, inner_params|
      question_id, looping_id = unique_id.split("_")
      id = inner_params[:delegate_answer_id]
      # Skip if Answer with answer_id has been deleted earlier
      next if inner_params[:answer_id].present? && !Answer.find_by_id(inner_params[:answer_id])
      answer = inner_params[:answer_id] ? Answer.find(inner_params[:answer_id]) : nil
#      looping_id = inner_params[:looping_id]
      value = inner_params[:value]
      if value.present?
        if id == 'new' && !answer
          question = Question.find(question_id)
          from_dependent_section, _ = question.nested_under_dependent_section?
          answer = Answer.find_or_create_new_answer(question, @authorization[:user], @result[:section].questionnaire, from_dependent_section, looping_id)
        end
        return if answer && answer.question_answered
        delegate_text_answer = id == 'new' ? DelegateTextAnswer.find_or_create_by_answer_id_and_user_id(answer.id, current_user.id) : DelegateTextAnswer.find_by_id(id)
        next unless delegate_text_answer
        if delegate_text_answer.user_id != current_user.id
          flash[:error] = "Not authorized to edit another delegate's answer"
        else
          delegate_text_answer.update_attributes(answer_text: value)
          flash[:notice] = "Delegate answer succesfully saved"
        end
      end
    end
  end

  def mark_as_answered
    if params[:question_answered]
      params[:question_answered].each do |id, val|
        # Skip if Answer with answer_id has been deleted earlier
        # This won't prevent the mark as answered checkbox to show for dependant answers
        # if a dependant section is destroyed and then recreated again.
        # AJAX calls would need to be implemented for those or the mark as answered
        # system to be reworked
        next unless Answer.find_by_id(id)
        answer = Answer.find(id)
        answer.update_attributes(question_answered: val)
        answered = val == "true" ? "answered" : "not answered"
        flash[:notice] = "Question marked as #{answered}".tap { |new_notice|
          new_notice.prepend("#{flash[:notice]}. ") if flash[:notice]
        }
      end
    end
  end

  def load_authorization(section, current_user_delegate=nil)
    if (current_user.is_admin_or_respondent_admin?) && params[:respondent_id].present?
      @respondent = User.find(params[:respondent_id])
      @authorization = @respondent ? @respondent.authorization_for(section, nil, @respondent.id) : false
    else
      @authorization = current_user ? current_user.authorization_for(section, current_user_delegate.try(:id)) : false
    end
  end

end
