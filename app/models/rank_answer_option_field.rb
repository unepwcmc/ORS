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
#  rank_answer_option_id :integer          not null
#  language              :string(255)      not null
#  option_text           :text
#  is_default_language   :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
