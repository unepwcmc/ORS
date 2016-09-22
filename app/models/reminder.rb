class Reminder < ActiveRecord::Base

  attr_protected :id, :created_at, :updated_at

  has_many :alerts, :dependent => :destroy
  has_many :deadlines, :through => :alerts

  validates :title, presence: true

  def associate_deadlines deadlines
    deadlines.each do |deadline_id|
      deadline = Deadline.find(deadline_id)
      if deadline
        self.alerts << Alert.create(:deadline_id => deadline_id)
      end
    end
  end

  def update_associated_deadlines deadlines
    to_remove = self.deadlines.map{ |deadline| deadline.id.to_s } - deadlines
    deadlines.each do |deadline_id|
      deadline = Deadline.find(deadline_id)
      if deadline && !self.deadlines.include?(deadline)
        self.alerts << Alert.create(:deadline => deadline)
      end
    end
    to_remove.each do |deadline_id|
      alert = self.alerts.find_by_deadline_id(deadline_id)
      if alert
        alert.destroy
      end
    end
  end
end

# == Schema Information
#
# Table name: reminders
#
#  id         :integer          not null, primary key
#  title      :text             not null
#  body       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  days       :integer
#
