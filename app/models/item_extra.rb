class ItemExtra < ActiveRecord::Base

  include LanguageMethods

  attr_accessible :extra_id
  
  ###
  ###   Relationships
  ###
  has_many :item_extra_fields, :dependent => :destroy
  belongs_to :extra
  belongs_to :loop_item_name
end

# == Schema Information
#
# Table name: item_extras
#
#  id                :integer          not null, primary key
#  loop_item_name_id :integer
#  extra_id          :integer
#  created_at        :datetime
#  updated_at        :datetime
#  original_id       :integer
#
