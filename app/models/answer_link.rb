class AnswerLink < ActiveRecord::Base
  attr_accessible :title, :url, :description
  belongs_to :answer
  validates :url, presence: true
end

# == Schema Information
#
# Table name: answer_links
#
#  id          :integer          not null, primary key
#  url         :text             not null
#  description :text
#  title       :string(255)
#  answer_id   :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
