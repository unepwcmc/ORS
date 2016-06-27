class ExtrasController < ApplicationController
  def new
    @loop_item_type = LoopItemType.find(params[:loop_item_type_id])
    @extra = @loop_item_type.extras.new
    respond_to do |format|
      format.js
    end
  end

  def create
    @loop_item_type = LoopItemType.find(params[:loop_item_type_id])
    @extra = @loop_item_type.extras.build(params[:extra])
    if @extra.save
      flash[:notice] = "Successfully created extra field."
      redirect_to @loop_item_type
    else
      render :action => 'new'
    end
  end

  def new_source
    @extra = Extra.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def upload_source
    @extra = Extra.find(params[:id])
    @status = {}
    @status[:errors] = []
    if params[:source].path
      if @extra.handle_source(params[:source].path, @status)
        flash[:notice] = "Source information added successfully"
      else
        flash[:error] = ""
        @status[:errors].each do |e|
          flash[:error] << e
        end
      end
    else
      flash[:error] = "Please provide a source file."
    end
    redirect_to @extra.loop_item_type
  end

  def destroy
    @extra = Extra.find(params[:id])
    @loop_item_type = @extra.loop_item_type
    @extra.destroy
    redirect_to @loop_item_type
  end
end
