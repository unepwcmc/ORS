class MatrixAnswerDropOption < ActiveRecord::Base

  include LanguageMethods

  belongs_to :matrix_answer
  has_many :matrix_answer_drop_option_fields, :dependent => :destroy
  accepts_nested_attributes_for :matrix_answer_drop_option_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :answer_part_matrix_options, :dependent => :destroy

  attr_accessible :matrix_answer_drop_option_fields_attributes

  def option_text language=nil
    result = language ? self.matrix_answer_drop_option_fields.find_by_language(language) : nil
    result ? result.option_text : self.matrix_answer_drop_option_fields.find_by_is_default_language(true).option_text
  end

end

# == Schema Information
#
# Table name: matrix_answer_drop_options
#
#  id               :integer          not null, primary key
#  matrix_answer_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  original_id      :integer
#
