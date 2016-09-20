class AnswerPartMatrixOption < ActiveRecord::Base

  belongs_to :answer_part, touch: true
  belongs_to :matrix_answer_option
  belongs_to :matrix_answer_drop_option

  attr_accessible :matrix_answer_option_id

end

# == Schema Information
#
# Table name: answer_part_matrix_options
#
#  id                           :integer          not null, primary key
#  answer_part_id               :integer          not null
#  matrix_answer_option_id      :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  answer_text                  :text
#  matrix_answer_drop_option_id :integer
#
