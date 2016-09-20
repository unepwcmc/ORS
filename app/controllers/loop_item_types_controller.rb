class LoopItemTypesController < ApplicationController
  def index
    @loop_item_types = LoopItemType.all
  end

  def show
    @loop_item_type = LoopItemType.find(params[:id], :include => [{:extras => :item_extras}, {:loop_item_names => :loop_item_name_fields}, :filtering_field])
    @questionnaire = @loop_item_type.root.loop_source.questionnaire
  end

  def new
    @loop_item_type = LoopItemType.new
  end

  def create
    @loop_item_type = LoopItemType.new(params[:loop_item_type])
    if @loop_item_type.save
      flash[:notice] = "Successfully created loop item type."
      redirect_to @loop_item_type
    else
      render :action => 'new'
    end
  end

  def edit
    @loop_item_type = LoopItemType.find(params[:id])
  end

  def update
    @loop_item_type = LoopItemType.find(params[:id])
    if @loop_item_type.update_attributes(params[:loop_item_type])
      flash[:notice] = "Successfully updated loop item type."
      redirect_to @loop_item_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    @loop_item_type = LoopItemType.find(params[:id])
    @loop_item_type.destroy
    flash[:notice] = "Successfully destroyed loop item type."
    redirect_to loop_item_types_url
  end

  def upload_item_names_source
    @loop_item_type = LoopItemType.find(params[:id])
    @status = {}
    @status[:errors] = []
    if params[:source].path
      if @loop_item_type.handle_source(params[:source].path, @status)
        flash[:notice] = "Loop items information added successfully"
      else
        flash[:error] = ""
        @status[:errors].each do |e|
          flash[:error] << e
        end
      end
    else
      flash[:error] = "Please provide a source file."
    end
    redirect_to @loop_item_type
  end
end
