class MultiAnswerOptionField < ActiveRecord::Base
  attr_accessible :language, :is_default_language, :option_text

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :multi_answer_option

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :multi_answer_option_id

  #validates_presence_of :help_text

  attr_accessible :language
end

# == Schema Information
#
# Table name: multi_answer_option_fields
#
#  id                     :integer          not null, primary key
#  language               :string(255)
#  option_text            :text
#  multi_answer_option_id :integer
#  created_at             :datetime
#  updated_at             :datetime
#  is_default_language    :boolean          default(FALSE)
#
