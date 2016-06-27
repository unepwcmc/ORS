class MatrixAnswerQuery < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  #attr_accessible :option_text, :help_text
  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  belongs_to :matrix_answer
  has_many :answer_parts, :as => :field_type
  has_many :matrix_answer_query_fields, :dependent => :destroy
  accepts_nested_attributes_for :matrix_answer_query_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  ###
  ###   Validations
  ###
  validates_associated :matrix_answer_query_fields


  def title language=nil
    result = language ? self.matrix_answer_query_fields.find_by_language(language) : nil
    result ? result.title : self.matrix_answer_query_fields.find_by_is_default_language(true).title
  end
end

# == Schema Information
#
# Table name: matrix_answer_queries
#
#  id               :integer          not null, primary key
#  matrix_answer_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#  original_id      :integer
#
