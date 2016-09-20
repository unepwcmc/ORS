class LoopItem < ActiveRecord::Base

  #attr_accessible :loop_item_type_id, :item_name, :parent_id, :lft, :rgt
  attr_protected :id

  LOOPING_ID_SEPARATOR = "S"

  ###
  ###   Plugins/Gems declarations
  ###
  acts_as_nested_set :dependent => :destroy

  ###
  ###   Relationships
  ###
  belongs_to :loop_item_type
  belongs_to :loop_item_name
  has_many :answers, dependent: :destroy
  has_many :user_section_submission_states, dependent: :destroy

  ###
  ###   Methods
  ###
  def self.available_loop_items( section, parent )
    if parent.loop_item_type && parent.loop_item_type.is_ancestor_of?(section.loop_item_type)
      return parent.loop_item.children
    else
      return parent.parent ? self.available_loop_items(section, parent.parent) : nil
    end
  end

  def item_name language=nil
    self.loop_item_name.item_name(language)
  end

  def fill_jqgrid
    cell = []
    cell << self.id
    self.ancestors.sort.each do |ancestor|
      cell << ancestor
    end
    cell << self
    cell
  end

  def update_name_from params, lang_code, default_lang
    update_field = self.loop_item_name.loop_item_name_fields.find_by_language(lang_code)
    if !update_field
      update_field = LoopItemNameField.create(:language => lang_code, :is_default_language => (lang_code == default_lang), :item_name => params[self.loop_item_type.name.to_sym])
      self.loop_item_name.loop_item_name_fields << update_field
    else
      update_field.item_name = params[self.loop_item_type.name.to_sym]
      update_field.save
    end
  end

  def <=> other
    self.sort_index <=> other.sort_index
  end

  def not_a_match?(operator, search_string, language)
    field = self.loop_item_name.loop_item_name_fields.find_by_language(language)
    case operator
      when "eq"
        field.nil? || field.item_name != search_string
      when "ne"
        field.nil? || field.item_name == search_string
      when "lt"
        field.nil? || field.item_name >= search_string
      when "le"
        field.nil? || field.item_name > search_string
      when "gt"
        field.nil? || field.item_name <= search_string
      when "ge"
        field.nil? || field.item_name < search_string
      when "bw"
        field.nil? || field.item_name.match(/#{search_string}(.*)/).nil?
      when "bn"
        field.nil? || field.item_name.match(/#{search_string}(.*)/)
      when "in"
        field.nil? || !(field.item_name =~ /#{search_string}/)
      when "ni"
        field.nil? || field.item_name =~ /#{search_string}/
      when "en"
        field.nil? || field.item_name.match(/(.*)#{search_string}/).nil?
      when "cn"
        field.nil? || field.item_name.match(/(.*)#{search_string}(.*)/).nil?
      when "nc"
        field.nil? || field.item_name.match(/(.*)#{search_string}(.*)/)
    end
  end

  def self.build_looping_identifier_for_responses_page params
    splitted = params.split("_")
    loop_items = []
    loop_item_types = []
    splitted.each do |name_id|
      loop_item_name = LoopItemName.find(name_id)
      loop_item_type = loop_item_name.loop_item_type
      loop_item_types << loop_item_type
      if loop_item_type.root?
        loop_items << loop_item_name.loop_items.where(loop_item_type_id: loop_item_type.id).first
      else
        parent_loop_item_type = loop_item_types.select{ |l| l.id == loop_item_type.parent_id }.first
        parent_loop_item = parent_loop_item_type && loop_items.select{ |g| g.loop_item_type_id == parent_loop_item_type.id }.first
        loop_item = parent_loop_item && loop_item_name.loop_items.where(loop_item_type_id: loop_item_type.id).find_by_parent_id(parent_loop_item.id)
        loop_items << loop_item unless loop_item.nil?
      end
    end
    loop_items.map(&:id).join(LoopItem::LOOPING_ID_SEPARATOR)
  end

end

# == Schema Information
#
# Table name: loop_items
#
#  id                :integer          not null, primary key
#  parent_id         :integer
#  lft               :integer
#  rgt               :integer
#  created_at        :datetime
#  updated_at        :datetime
#  loop_item_type_id :integer
#  sort_index        :integer          default(0)
#  loop_item_name_id :integer
#  original_id       :integer
#
