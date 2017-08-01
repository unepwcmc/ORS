class UserDelegate < ActiveRecord::Base

  extend EnumerateIt
  has_enumeration_for :state, :with => UserDelegateStates, :create_helpers => true #check in enumerations/user_delegate_status.rb

  belongs_to :user
  belongs_to :delegate, :class_name => "User"
  has_many :delegations, :dependent => :destroy

  validates_uniqueness_of :user_id, :scope => :delegate_id

  attr_accessible :user_id, :delegate_id, :details, :delegations_attributes

  accepts_nested_attributes_for :delegations

  def <=>other
    self.delegate.full_name <=> other.delegate.full_name
  end
end

# == Schema Information
#
# Table name: user_delegates
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  delegate_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  state       :integer          default(0)
#
