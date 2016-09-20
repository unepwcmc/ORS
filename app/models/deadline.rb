class Deadline < ActiveRecord::Base

  attr_protected :id, :created_at, :updated_at

  belongs_to :questionnaire
  has_many :alerts, :dependent => :destroy
  has_many :reminders, :through => :alerts
  validates :questionnaire_id, presence: true
end

# == Schema Information
#
# Table name: deadlines
#
#  id               :integer          not null, primary key
#  title            :text             not null
#  soft_deadline    :boolean          default(FALSE)
#  due_date         :datetime
#  questionnaire_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
