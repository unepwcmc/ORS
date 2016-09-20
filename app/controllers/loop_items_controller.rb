class LoopItemsController < ApplicationController
  def index
    @loop_items = LoopItem.all
  end

  def new
    @loop_item = LoopItem.new
  end

  def create
    @loop_item = LoopItem.new(params[:loop_item])
    if @loop_item.save
      flash[:notice] = "Successfully created loop item."
      redirect_to @loop_item
    else
      render :action => 'new'
    end
  end

  def show
    @loop_item = LoopItem.find(params[:id])
  end

  def edit
    @loop_item = LoopItem.find(params[:id])
  end

  def update
    @loop_item = LoopItem.find(params[:id])
    if @loop_item.update_attributes(params[:loop_item])
      flash[:notice] = "Successfully updated loop item."
      redirect_to @loop_item
    else
      render :action => 'edit'
    end
  end

  def destroy
    @loop_item = LoopItem.find(params[:id])
    @loop_item.destroy
    flash[:notice] = "Successfully destroyed loop item."
    redirect_to loop_items_url
  end
end
