class ItemExtraField < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  attr_accessible :language

  ###
  ###   Relationships
  ###
  belongs_to :item_extra
end

# == Schema Information
#
# Table name: item_extra_fields
#
#  id                  :integer          not null, primary key
#  item_extra_id       :integer
#  language            :string(255)      default("en")
#  value               :string(255)
#  is_default_language :boolean          default(FALSE)
#  created_at          :datetime
#  updated_at          :datetime
#
