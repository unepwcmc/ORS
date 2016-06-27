class MatrixAnswerQueryField < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :matrix_answer_query

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :matrix_answer_query_id

  attr_accessible :language, :is_default_language, :title

end

# == Schema Information
#
# Table name: matrix_answer_query_fields
#
#  id                     :integer          not null, primary key
#  matrix_answer_query_id :integer
#  language               :string(255)
#  title                  :text
#  is_default_language    :boolean
#  created_at             :datetime
#  updated_at             :datetime
#
