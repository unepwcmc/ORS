class Alert < ActiveRecord::Base

  attr_protected :id, :created_at, :updated_at

  belongs_to :deadline
  belongs_to :reminder

  validates_uniqueness_of :deadline_id, :scope => :reminder_id
  validates :reminder_id, presence: true
  validates :deadline_id, presence: true
end

# == Schema Information
#
# Table name: alerts
#
#  id          :integer          not null, primary key
#  deadline_id :integer          not null
#  reminder_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
