class MatrixAnswerDropOptionField < ActiveRecord::Base

  include LanguageMethods

  belongs_to :matrix_answer_drop_option

  validates_uniqueness_of :language, :scope => :matrix_answer_drop_option_id

  attr_accessible :language, :is_default_language, :option_text
  
end

# == Schema Information
#
# Table name: matrix_answer_drop_option_fields
#
#  id                           :integer          not null, primary key
#  matrix_answer_drop_option_id :integer
#  language                     :string(255)
#  is_default_language          :boolean
#  option_text                  :string(255)
#  created_at                   :datetime
#  updated_at                   :datetime
#
