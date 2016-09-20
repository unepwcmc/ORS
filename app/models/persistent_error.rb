class PersistentError < ActiveRecord::Base
  belongs_to :errorable, :polymorphic => true
  belongs_to :user

  attr_accessible :details, :user_id, :user_ip, :timestamp
end

# == Schema Information
#
# Table name: persistent_errors
#
#  id             :integer          not null, primary key
#  title          :string(255)
#  details        :text
#  timestamp      :datetime
#  user_id        :integer          not null
#  errorable_type :string(255)
#  errorable_id   :integer
#  user_ip        :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
