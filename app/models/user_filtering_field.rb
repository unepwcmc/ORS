class UserFilteringField < ActiveRecord::Base

  attr_accessible :user_id, :filtering_field_id, :field_value
  ###
  ### Relationships
  ###

  belongs_to :user
  belongs_to :filtering_field

  ###
  ###  Validations
  ###
  validates_uniqueness_of :user_id, :scope => :filtering_field_id
end

# == Schema Information
#
# Table name: user_filtering_fields
#
#  id                 :integer          not null, primary key
#  user_id            :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  filtering_field_id :integer          not null
#  field_value        :string(255)
#
