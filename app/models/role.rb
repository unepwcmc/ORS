class Role < ActiveRecord::Base

  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###

  has_many :users, :through => :assignments
  has_many :assignments, :dependent => :destroy

  scope :order_by_index, -> { order(:order_index) }
end

# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
