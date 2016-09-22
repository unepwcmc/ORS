class DelegateTextAnswer < ActiveRecord::Base

  attr_accessible :answer_id, :user_id, :answer_text, :created_at, :updated_at

  belongs_to :answer
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :answer_id

end

# == Schema Information
#
# Table name: delegate_text_answers
#
#  id          :integer          not null, primary key
#  answer_id   :integer          not null
#  user_id     :integer          not null
#  answer_text :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
