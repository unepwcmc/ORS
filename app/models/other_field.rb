class OtherField < ActiveRecord::Base
  attr_accessible :language, :is_default_language

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :multi_answer

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :multi_answer_id

  attr_accessible :language, :is_default_language, :other_text
end

# == Schema Information
#
# Table name: other_fields
#
#  id                  :integer          not null, primary key
#  language            :string(255)
#  other_text          :text
#  multi_answer_id     :integer
#  is_default_language :boolean
#  created_at          :datetime
#  updated_at          :datetime
#
