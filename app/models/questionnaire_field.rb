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
#  language             :string(255)      not null
#  title                :text
#  questionnaire_id     :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  introductory_remarks :text
#  is_default_language  :boolean          default(FALSE), not null
#  email_subject        :string(255)      default("Online Reporting System")
#  email                :text
#  email_footer         :string(255)
#  submit_info_tip      :text
#
