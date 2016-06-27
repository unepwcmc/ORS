class LoopItemNameField < ActiveRecord::Base
  ###
  ###   Include Libs
  ###
  include LanguageMethods

  attr_accessible :language, :item_name, :is_default_language

  ###
  ###   Relationships
  ###
  belongs_to :loop_item_name

  ###
  ###   Validations
  ###
  validates_uniqueness_of :language, :scope => :loop_item_name_id
end

# == Schema Information
#
# Table name: loop_item_name_fields
#
#  id                  :integer          not null, primary key
#  language            :string(255)
#  item_name           :string(255)
#  is_default_language :boolean
#  loop_item_name_id   :integer
#  created_at          :datetime
#  updated_at          :datetime
#
