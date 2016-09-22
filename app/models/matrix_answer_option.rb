class MatrixAnswerOption < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  belongs_to :matrix_answer #=> belongs to a multi_answer type answer.
  has_many :matrix_answer_option_fields, :dependent => :destroy
  accepts_nested_attributes_for :matrix_answer_option_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :answer_part_matrix_options, :dependent => :destroy

  ###
  ###   Validations
  ###
  validates_associated :matrix_answer_option_fields

  def title language=nil
    result = language ? self.matrix_answer_option_fields.find_by_language(language) : nil
    result ? result.title : self.matrix_answer_option_fields.find_by_is_default_language(true).title
  end

end

# == Schema Information
#
# Table name: matrix_answer_options
#
#  id               :integer          not null, primary key
#  matrix_answer_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  original_id      :integer
#
