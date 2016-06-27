class UserFilteringField < ActiveRecord::Base

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
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  filtering_field_id :integer
#  field_value        :string(255)
#
