class QuestionnaireField < ActiveRecord::Base
  ###
  ###   Include Libs
  ###
  include LanguageMethods

  attr_accessible :language, :title, :is_default_language, :introductory_remarks, :email_subject, :email_footer, :email, :submit_info_tip

  ###
  ###   Relationships
  ###
  belongs_to :questionnaire

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :questionnaire_id
  #validates_presence_of :title

  ###
  ###   Methods
  ###
end


# == Schema Information
#
# Table name: questionnaire_fields
#
#  id                   :integer          not null, primary key
#  language             :string(255)
#  title                :text
#  questionnaire_id     :integer
#  created_at           :datetime
#  updated_at           :datetime
#  introductory_remarks :text
#  is_default_language  :boolean         default(FALSE)
#  email_subject        :string(255)     default("[Online Reporting System]")
#  email                :text
#  email_footer         :string(255)
#  submit_info_tip      :text
#
