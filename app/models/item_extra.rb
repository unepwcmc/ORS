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
#  loop_item_name_id :integer          not null
#  extra_id          :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  original_id       :integer
#
