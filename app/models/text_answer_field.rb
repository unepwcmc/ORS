class TextAnswerField < ActiveRecord::Base

  #attr_accessible :width, :rows, :help_text
  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###

  belongs_to :text_answer
  has_many :answer_parts, :as => :field_type, :dependent => :destroy

  ###
  ###   Validations
  ###

  ###
  ###   Methods
  ###

end

# == Schema Information
#
# Table name: text_answer_fields
#
#  id             :integer          not null, primary key
#  text_answer_id :integer          not null
#  rows           :integer          default(5), not null
#  width          :integer          default(600), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  original_id    :integer
#
