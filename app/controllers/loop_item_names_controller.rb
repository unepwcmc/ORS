class LoopItemNamesController < ApplicationController
  def show
    @loop_item_name = LoopItemName.find(params[:id], :include => [{:loop_source => {:questionnaire => :questionnaire_fields}}, {:loop_item_type => :filtering_field}, :loop_item_name_fields])
    @questionnaire = @loop_item_name.loop_source.questionnaire
  end
end
