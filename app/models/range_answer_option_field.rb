class RangeAnswerOptionField < ActiveRecord::Base
  attr_accessible :language, :is_default_language, :option_text

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :range_answer_option

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :range_answer_option_id
end

# == Schema Information
#
# Table name: range_answer_option_fields
#
#  id                     :integer          not null, primary key
#  range_answer_option_id :integer
#  option_text            :string(255)
#  language               :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  is_default_language    :boolean
#
