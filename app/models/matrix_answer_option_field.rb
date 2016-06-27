class MatrixAnswerOptionField < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :matrix_answer_option

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :matrix_answer_option_id
  
  attr_accessible :language, :is_default_language, :title, :matrix_answer_option_id
  
end

# == Schema Information
#
# Table name: matrix_answer_option_fields
#
#  id                      :integer          not null, primary key
#  matrix_answer_option_id :integer
#  language                :string(255)
#  title                   :text
#  is_default_language     :boolean
#  created_at              :datetime
#  updated_at              :datetime
#
