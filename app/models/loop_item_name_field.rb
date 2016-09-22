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
  validates :item_name, presence: true
end

# == Schema Information
#
# Table name: loop_item_name_fields
#
#  id                  :integer          not null, primary key
#  language            :string(255)      not null
#  item_name           :text             not null
#  is_default_language :boolean          default(FALSE), not null
#  loop_item_name_id   :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
