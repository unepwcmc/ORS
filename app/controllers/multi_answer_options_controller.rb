class MultiAnswerOptionsController < ApplicationController

  def update_index
    params["data"].each do |o|
      multi_option = MultiAnswerOption.find( Integer(o[1]) )
      multi_option.sort_index = Integer(o[0])
      multi_option.save()
    end
    render :nothing => true
  end

end
