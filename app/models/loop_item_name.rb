class LoopItemName < ActiveRecord::Base

  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :loop_source
  belongs_to :loop_item_type
  has_many :loop_items, :dependent => :destroy
  has_many :item_extras
  has_many :extras, :through => :item_extras
  has_many :loop_item_name_fields, :dependent => :destroy
  has_many :delegated_loop_item_names
  has_many :delegation_sections, :through => :delegated_loop_item_names


  ###
  ###   Methods
  ###

  #fetchs the item_name in language or the default item name. (Through loop_item_name_fields)
  def item_name language=nil
    result = language ? self.loop_item_name_fields.find_by_language(language) : nil
    result ? result.item_name : self.loop_item_name_fields.find_by_is_default_language(true).item_name
  end

  def <=>(loop_item_name)
    item_name <=> loop_item_name.item_name
  end
end

# == Schema Information
#
# Table name: loop_item_names
#
#  id                :integer          not null, primary key
#  loop_source_id    :integer
#  loop_item_type_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#  original_id       :integer
#
