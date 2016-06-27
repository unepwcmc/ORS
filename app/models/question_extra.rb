class QuestionExtra < ActiveRecord::Base
  attr_accessible :extra_id
  ###
  ###   Relationships
  ###
  belongs_to :question
  belongs_to :extra
end

# == Schema Information
#
# Table name: question_extras
#
#  id          :integer          not null, primary key
#  question_id :integer
#  extra_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#
