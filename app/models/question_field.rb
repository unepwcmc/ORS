class QuestionField < ActiveRecord::Base
  attr_accessible :language, :is_default_language, :short_title, :title,
    :description

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :question
  #belongs_to :generated_question

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => [:question_id] #a section field of each language per section
  #validates_presence_of :title, :short_title, :description

end

# == Schema Information
#
# Table name: question_fields
#
#  id                  :integer          not null, primary key
#  language            :string(255)
#  title               :text
#  short_title         :string(255)
#  description         :text
#  question_id         :integer
#  created_at          :datetime
#  updated_at          :datetime
#  is_default_language :boolean          default(FALSE)
#
