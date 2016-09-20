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
#  question_id :integer          not null
#  extra_id    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
