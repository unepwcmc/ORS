class RangeAnswerOption < ActiveRecord::Base

  include LanguageMethods

  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  belongs_to :range_answer
  has_many :answer_parts, :as => :field_type, :dependent => :destroy
  has_many :range_answer_option_fields, :dependent => :destroy
  accepts_nested_attributes_for :range_answer_option_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  ###
  ###   Validations
  ###
  validates_associated :range_answer_option_fields

  def option_text language=nil
    result = language ? self.range_answer_option_fields.find_by_language(language) : nil
    result ? result.option_text : self.range_answer_option_fields.find_by_is_default_language(true).option_text
  end

  def <=>(range_answer_option)
    sort_index <=> range_answer_option.sort_index
  end

end

# == Schema Information
#
# Table name: range_answer_options
#
#  id              :integer          not null, primary key
#  range_answer_id :integer          not null
#  sort_index      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  original_id     :integer
#
