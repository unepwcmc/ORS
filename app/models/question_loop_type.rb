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
#  question_id       :integer          not null
#  loop_item_type_id :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
