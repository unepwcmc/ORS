class RankAnswerOptionField < ActiveRecord::Base
  attr_accessible :language, :option_text, :is_default_language

  include LanguageMethods

  belongs_to :rank_answer_option

  validates_uniqueness_of :language, :scope => :rank_answer_option_id

end

# == Schema Information
#
# Table name: rank_answer_option_fields
#
#  id                    :integer          not null, primary key
#  rank_answer_option_id :integer
#  language              :string(255)
#  option_text           :text
#  is_default_language   :boolean
#  created_at            :datetime
#  updated_at            :datetime
#
