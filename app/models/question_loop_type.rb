class QuestionLoopType < ActiveRecord::Base

  attr_accessible :loop_item_type_id

  ###
  ###   Relationships
  ###
  belongs_to :question
  belongs_to :loop_item_type
end

# == Schema Information
#
# Table name: question_loop_types
#
#  id                :integer          not null, primary key
#  question_id       :integer
#  loop_item_type_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#
