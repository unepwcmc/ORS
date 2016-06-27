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
#  text_answer_id :integer
#  rows           :integer
#  width          :integer
#  created_at     :datetime
#  updated_at     :datetime
#  original_id    :integer
#
