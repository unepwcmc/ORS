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
#  matrix_answer_query_id :integer          not null
#  language               :string(255)      not null
#  title                  :text
#  is_default_language    :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
