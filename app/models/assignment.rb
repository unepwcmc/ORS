class Assignment < ActiveRecord::Base

  ###
  ###   Relationships
  ###
  belongs_to :user
  belongs_to :role

  ###
  ###   Validations
  ###
  validates_uniqueness_of :user_id, :scope => :role_id
end

# == Schema Information
#
# Table name: assignments
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  role_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
