class FilteringFieldsController < ApplicationController

  authorize_resource

  # GET /filtering_fields
  # GET /filtering_fields.xml
  def index
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => {:filtering_fields => :loop_item_types})
    @filtering_fields = @questionnaire.filtering_fields

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @filtering_fields }
    end
  end

  # GET /filtering_fields/1
  # GET /filtering_fields/1.xml
  def show
    @filtering_field = FilteringField.find(params[:id], :include => [{:loop_item_types => [:loop_source]}, {:questionnaire => :questionnaire_fields}])
    @questionnaire = @filtering_field.questionnaire
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @filtering_field }
    end
  end

  # GET /filtering_fields/new
  # GET /filtering_fields/new.xml
  def new
    @questionnaire = Questionnaire.find(params[:questionnaire_id], :include => [{:loop_sources => :loop_item_type}])
    @filtering_field = @questionnaire.filtering_fields.build
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @filtering_field }
    end
  end

  # POST /filtering_fields
  # POST /filtering_fields.xml
  def create
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    @filtering_field = @questionnaire.filtering_fields.create(:name => params[:filtering_field][:name])
    params[:filtering_field][:loop_item_types].each do |loop_source_id, item_type_id|
      if item_type_id.present?
        @filtering_field.loop_item_types << LoopItemType.find(item_type_id.to_i)
      end
    end

    respond_to do |format|
      if @filtering_field.save
        flash[:notice] = 'Filtering field was successfully created.'
        format.html { redirect_to([@questionnaire, @filtering_field]) }
        format.xml  { render :xml => @filtering_field, :status => :created, :location => @filtering_field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @filtering_field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /filtering_fields/1/edit
  def edit
    @filtering_field = FilteringField.find(params[:id], :include => [:questionnaire, :loop_item_types])
    @questionnaire = @filtering_field.questionnaire
  end

  # PUT /filtering_fields/1
  # PUT /filtering_fields/1.xml
  def update
    @filtering_field = FilteringField.find(params[:id], :include => :loop_item_types)

    @filtering_field.name  = params[:filtering_field][:name]
    params[:filtering_field][:loop_item_types].each do |loop_source_id, item_type_id|
      if item_type_id.present?
        loop_item_type = LoopItemType.find(item_type_id.to_i)
        @filtering_field.loop_item_types << loop_item_type unless loop_item_type.filtering_field.present?
      else
        possibly_to_remove = LoopSource.find(loop_source_id, :include => :loop_item_type).loop_item_type.self_and_descendants.map{ |a| a.id }
        item_type_to_remove = LoopItemType.find_by_id((possibly_to_remove & @filtering_field.loop_item_types.map{ |a| a.id })[0])
        if item_type_to_remove
          item_type_to_remove.filtering_field_id = nil
          item_type_to_remove.save
        end
      end
    end
    respond_to do |format|
      if @filtering_field.save
        flash[:notice] = 'FilteringField was successfully updated.'
        format.html { redirect_to([@filtering_field.questionnaire,@filtering_field]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @filtering_field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /filtering_fields/1
  # DELETE /filtering_fields/1.xml
  def destroy
    @filtering_field = FilteringField.find(params[:id], :include => :questionnaire)
    @questionnaire = @filtering_field.questionnaire
    @filtering_field.destroy

    respond_to do |format|
      format.html { redirect_to(questionnaire_filtering_fields_path(@questionnaire)) }
      format.xml  { head :ok }
    end
  end
end
