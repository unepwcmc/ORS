class LoopItemName < ActiveRecord::Base

  include LanguageMethods

  ###
  ###   Relationships
  ###
  belongs_to :loop_source
  belongs_to :loop_item_type
  has_many :loop_items, :dependent => :destroy
  has_many :item_extras, dependent: :destroy
  has_many :extras, :through => :item_extras
  has_many :loop_item_name_fields, :dependent => :destroy
  has_many :delegated_loop_item_names, dependent: :destroy
  has_many :delegation_sections, :through => :delegated_loop_item_names

  ###
  ###   Methods
  ###

  #fetchs the item_name in language or the default item name. (Through loop_item_name_fields)
  def item_name language=nil
    if language
      result = self.loop_item_name_fields.find{ |f| f.language == language }
    end
    result ||= self.loop_item_name_fields.find{ |f| f.is_default_language }
    result.try(:item_name)
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
