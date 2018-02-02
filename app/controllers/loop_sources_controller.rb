class LoopSourcesController < ApplicationController

  authorize_resource

  def index
    #@loop_sources = LoopSource.all
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => [{:loop_sources => :loop_item_type}, :questionnaire_fields])
    @loop_sources = @questionnaire.loop_sources
  end

  def new
    #@loop_source = LoopSource.new
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    @loop_source = @questionnaire.loop_sources.build
    @loop_source.source_files.build
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    @loop_source = @questionnaire.loop_sources.create(params[:loop_source])
    if @loop_source.save
      #@loop_source.parse_loop_source_files current_user.id, current_user.current_login_ip
      ParseLoopSourceFiles.perform_async(current_user.id, current_user.current_login_ip, @loop_source.id)
      flash[:notice] = "Loop source (#{@loop_source.name}) is being uploaded, please check questionnaire page for progress information."
    else
      flash[:error] = "Uploading loop source failed."
    end
    respond_to do |format|
      format.js
      format.html { redirect_to questionnaire_loop_sources_path(@questionnaire) }
    end
  end

  def show
    @loop_source = LoopSource.find(params[:id], :include => [ {:questionnaire => :questionnaire_fields}, {:loop_item_type => [:loop_item_names, :loop_items]} ])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @loop_source = LoopSource.find(params[:id])
    @loop_source.source_files.build
  end

  def update
    @loop_source = LoopSource.find(params[:id], :include => :loop_item_type)
    if @loop_source.source_files.size == 0 && @loop_source.loop_item_type.nil?
      @loop_source.update_sections
    end
    if @loop_source.update_attributes(params[:loop_source])
      #@loop_source.parse_loop_source_files(current_user.id, current_user.current_login_ip) if @loop_source.unparsed_sources?
      ParseLoopSourceFiles.perform_async(current_user.id, current_user.current_login_ip, @loop_source.id) if @loop_source.unparsed_sources?
      flash[:notice] = "Successfully updated loop source. New file is being uploaded"
      redirect_to @loop_source
    else
      render :action => 'edit'
    end
  end

  def destroy
    @loop_source = LoopSource.find(params[:id], :include => [:questionnaire, :loop_item_type])
    @questionnaire = @loop_source.questionnaire
    #@loop_source.destroy_related_objects
    if @loop_source.delete_smoothly
      flash[:notice] = "Successfully destroyed loop source."
    else
      flash[:error] = "There was an error removing this loop source, please try again later."
    end
    respond_to do |format|
      format.js
      format.html { redirect_to questionnaire_loop_sources_path(@questionnaire) }
    end
  end

  def item_types
    #Get the parent section of the section being created: To help maintain the hierarchy between item_types
    @parent_section = ( params[:parent_id] == "0" ? nil : Section.find(params[:parent_id]) ) if params[:parent_id]
    #if the section is being edited, rather than created the parent_id doesn't exist && so the
    #section is used itself instead
    @section = Section.find(params[:section_id]) if params[:section_id]
    @item_types = LoopSource.get_item_types(params)
    respond_to do |format|
      format.js
    end
  end

  def fill_jqgrid
    loop_source = LoopSource.find(params[:id])
    grid_details = {}
    loop_source.fill_jqgrid grid_details, params
    @json = {:page => params[:page], :records => grid_details[:total_records], :total => grid_details[:total_pages]}
    @json[:rows] = grid_details[:rows]
    respond_to do |format|
      format.js { render :json => @json.to_json, :callback => params[:callback] }
    end
  end

  def jqgrid_update
    loop_source = LoopSource.find(params[:id])
    if params[:oper] == "edit"
      loop_source.update_records params
      flash[:notice] = "Record successfully updated"
    else
      loop_source.delete_record params
      flash[:notice] = "Record successfully destroyed"
    end
    respond_to do |format|
      format.js
    end
  end

end
