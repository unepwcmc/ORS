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
#  range_answer_option_id :integer          not null
#  option_text            :string(255)
#  language               :string(255)      not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  is_default_language    :boolean          default(FALSE), not null
#
