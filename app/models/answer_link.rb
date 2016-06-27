class AnswerLink < ActiveRecord::Base
  attr_accessible :title, :url, :description
  belongs_to :answer
end

# == Schema Information
#
# Table name: answer_links
#
#  id          :integer          not null, primary key
#  url         :text
#  description :text
#  title       :string(255)
#  answer_id   :integer
#  created_at  :datetime
#  updated_at  :datetime
#
