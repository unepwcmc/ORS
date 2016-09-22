class AnswerTypeField < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :answer_type, :polymorphic => true

  attr_accessible :language, :is_default_language, :help_text, :answer_type_type
end

# == Schema Information
#
# Table name: answer_type_fields
#
#  id                  :integer          not null, primary key
#  language            :string(255)      not null
#  help_text           :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  is_default_language :boolean          default(FALSE), not null
#  answer_type_type    :string(255)
#  answer_type_id      :integer
#
