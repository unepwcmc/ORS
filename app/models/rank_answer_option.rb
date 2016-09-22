class RankAnswerOption < ActiveRecord::Base
  attr_accessible :rank_answer_option_fields_attributes

  include LanguageMethods

  belongs_to :rank_answer
  has_many :rank_answer_option_fields
  accepts_nested_attributes_for :rank_answer_option_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :answer_parts, :as => :field_type, :dependent => :destroy

  def option_text language=nil
    result = language ? self.rank_answer_option_fields.find_by_language(language) : nil
    result ? result.option_text : self.rank_answer_option_fields.find_by_is_default_language(true).option_text
  end
end

# == Schema Information
#
# Table name: rank_answer_options
#
#  id             :integer          not null, primary key
#  rank_answer_id :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  original_id    :integer
#
