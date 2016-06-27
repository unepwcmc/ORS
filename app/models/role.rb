class Role < ActiveRecord::Base

  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  
  has_many :users, :through => :assignments
  has_many :assignments, :dependent => :nullify
end

# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
