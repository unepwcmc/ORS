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

  validates :value, presence: true
end

# == Schema Information
#
# Table name: item_extra_fields
#
#  id                  :integer          not null, primary key
#  item_extra_id       :integer          not null
#  language            :string(255)      default("en"), not null
#  value               :text             not null
#  is_default_language :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
