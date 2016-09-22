class LoopItemType < ActiveRecord::Base
  require 'csv'

  #attr_accessible :name, :parent_id, :lft, :rgt
  attr_protected :id

  ###
  ###   Plugins/Gems declarations
  ###
  acts_as_nested_set :dependent => :destroy

  before_destroy :destroy_loop_items

  ###
  ###   Relationships
  ###
  belongs_to :loop_source
  has_many :loop_items, dependent: :destroy
  has_many :loop_item_names, :dependent => :destroy, :include => :loop_item_name_fields
  has_many :loop_item_name_fields, :through => :loop_item_names
  has_many :extras, :dependent => :destroy
  belongs_to :filtering_field
  has_many :sections, :dependent => :nullify
  has_many :question_loop_types, :dependent => :destroy
  has_many :questions, :through => :question_loop_types

  ###
  ###   METHODS
  ###

  #get the first occurrence of an item of self.loop_source that is an ancestor of section
  def get_upper_boundary(section)
    if section.matching_loop_sources?(self)
      section.loop_item_type
    else
      section.root? ? nil : !section.parent ?  nil : section.parent.first_ancestor_item_type(self)
    end
  end

  #get the first occurrence of an item of self.loop_source that is an ancestor of section | for when editing a section.
  def get_upper_boundary_when_editing(section)
    !section.parent ? nil : section.parent.first_ancestor_item_type(self)
  end

  #get the first occurrence of an item of self.loop_source that is a descendant of section
  def get_bottom_boundary(section)
    ( !section.children || section.leaf? ) ? nil : section.descendant_item_type(self)
  end

  #check if a loop_item_type is inside the upper and bottom boundary for a specific section.
  def in_bounds?(upper_boundary)
    !upper_boundary || self.is_descendant_of?(upper_boundary)
  end

  def in_bounds_when_editing?(bottom_boundary, upper_boundary)
    if !upper_boundary && !bottom_boundary  #if both are nil return true
      return true
    elsif upper_boundary && !bottom_boundary && self.is_descendant_of?(upper_boundary)
      return true
    elsif !upper_boundary && bottom_boundary && self.is_ancestor_of?(bottom_boundary)
      return true
    elsif upper_boundary && bottom_boundary && self.is_descendant_of?(upper_boundary) && self.is_ancestor_of?(bottom_boundary)
      return true
    else
      return false
    end
  end

  def is_filtering_field?
    self.filtering_field.present?
  end

  def handle_source file_path, status
    status[:line] = 0

    # get the default language of the questionnaire
    default_lang = self.root.loop_source
      .questionnaire
      .questionnaire_fields
      .find_by_is_default_language(true)
      .language

    begin
      # read the file into a table
      if File.open(file_path, &:readline).match(/;/) == nil
        separator = ','
      else
        separator = ';'
      end

      table = CSV.read(file_path, {
        :quote_char => '"',
        :col_sep =>separator,
        :row_sep =>:auto,
        :headers => :first_row,
        :encoding => "u"
      })
    rescue => e
      status[:errors] << e.message
      return false
    end

    # check if the headers of the file are OK.
    # OK if the first char is a "#", if the first element is the name of the loop item type, and if the following header items are one of the UN languages
    if !self.source_headers_ok?(table.headers.to_a, status)
      return false
    end

    # parse the file, row by row
    table.each do |row|

      # keep track of the line number
      status[:line] += 1
      # convert the row to an array
      row_as_a = row.to_a

      if row_as_a.present?
        #the_name = row_as_a[0][1].squeeze(" ").strip
        item_name_utf8 = row_as_a[0][1].squeeze(" ").strip # (cd['confidence'] > 0.9 && cd['confidence'] < 1) ? Iconv.iconv('utf-8', cd['encoding'], the_name) : the_name

        # check if there's a loop_item_names with the value of the first column of each row
        loop_item_name = self.loop_item_name_fields.find_by_item_name_and_language(item_name_utf8.to_s, default_lang).try(:loop_item_name)#row_as_a[0][1])

        # if not, return with info about the error
        if !loop_item_name
          #ignore errors and continue
          status[:errors] << "ERROR: Line number #{status[:line]}. There is no loop item by the name of: #{item_name_utf8}"
          #return false
          next
        end

        # remove the first column
        row_as_a.delete_at(0)

        # add the extra_fields to the item_extras object. Storing the language
        row_as_a.each_index do |i| # row_as_a[i][0] => header; row_as_a[i][1] => value
          if row_as_a[i][1].present? # if there's no name, there's no item
            the_val=row_as_a[i][1].squeeze(" ").strip
            the_lang = row_as_a[i][0].squeeze(" ").strip

            # check if there's already a item_extra_field with the current language: if not, create it and then update the values.
            loop_item_name_field = loop_item_name.loop_item_name_fields.find_or_create_by_language(the_lang)#lang_utf8.to_s)#
            loop_item_name_field.is_default_language = (default_lang == the_lang)#lang_utf8.to_s)#
            loop_item_name_field.item_name = the_val

            begin
              loop_item_name_field.save!
            rescue
              loop_item_name_field.item_name = the_val.force_encoding("ISO-8859-1").encode("UTF-8").to_s
              if !loop_item_name_field.save!
                status[:errors] << "ERROR: Line number #{status[:line]}: please check the character encoding of your file."
              end
            end

          end
        end
      end
    end

    true
  end

  def source_headers_ok? header_row, status
    #check if headers are present: Headers/Title line should start with "#"
    if !['#'].include?(header_row[0].to_s[0,1]) && "\357" != header_row[0].to_s[0,1]
      status[:errors] << "ERROR: Header row is not properly defined. Should start with a # character."
      return false
    else
      #remove the '#' character, since it is no longer needed
      first_elem = header_row[0][1..-1]
      if first_elem.squeeze(" ").strip.downcase != self.name.squeeze(" ").strip.downcase
        status[:errors] << "ERROR: Header row. First element must be the type of the loop items."
        return false
      else
        header_row.delete_at(0)
      end
      languages = self.root.loop_source.questionnaire.questionnaire_fields.map{ |a| a.language.squeeze(" ").strip }
      header_row.each do |header|
        if !header || !languages.include?(header.squeeze(" ").strip)
          status[:errors] << "ERROR: Header row. The loop items name values can only be defined in the languages of the questionnaire. (#{languages.join(', ')})."
          return false
        end
      end
    end
    true
  end

  def leaf_loop_items_sorted(params)
    if params[:sord] == "asc"
      result = self.loop_items.sort{ |a, b| a.item_name(params[:language]) <=> b.item_name(params[:language]) }
    else
      result = self.loop_items.sort{ |a, b| b.item_name(params[:language]) <=> a.item_name(params[:language]) }
    end
    self.leaf? ? result : result.map{ |a| a.leaves }.flatten
  end

  #Fetches the LoopItemName that has a a loop_item_name_field with item_name as 'the_name'
  #Passes in the default language to specify if a new LoopItemNameField needs to be created
  def loop_item_name_with the_name, default_language, loop_source
    #l_item_name = item_types[row_as_a[i][0].to_s].loop_item_names.find_by_item_name(row_as_a[i][1].to_s)
    the_name_db_safe = the_name
    begin
      the_l_item_name_field = self.loop_item_name_fields.find_by_item_name(the_name)
    rescue
      the_name_db_safe = the_name.force_encoding("ISO-8859-1").encode("UTF-8").to_s
      the_l_item_name_field = self.loop_item_name_fields.find_by_item_name(the_name_db_safe)
    end

    l_item_name = the_l_item_name_field.present? ? the_l_item_name_field.loop_item_name : nil

    return l_item_name if l_item_name

    l_item_name = LoopItemName.new()
    l_item_name.loop_item_type_id = self.id
    l_item_name.loop_source_id = loop_source.id

    l_item_name.transaction do
      l_item_name.save!

      l_item_name_field = l_item_name.loop_item_name_fields.build(
        item_name: the_name_db_safe,
        language: default_language,
        is_default_language: true
      )

      l_item_name_field.save!
    end

    l_item_name
  end

  def existing_item_with( the_name, parent, default_language)
    if parent
      parent.children.each do |child|
        if child.loop_item_type == self && child.item_name(default_language).downcase == the_name.downcase
          return child
        end
      end
    else
      self.loop_items.each do |item|
        if item.item_name(default_language).downcase == the_name.downcase
          return item
        end
      end
    end
    nil
  end

  private
  def destroy_loop_items
    self.loop_items.first.root.destroy if self.loop_items.present? && self.loop_items.first.root.present?
  end
end

# == Schema Information
#
# Table name: loop_item_types
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  parent_id          :integer
#  lft                :integer
#  rgt                :integer
#  loop_source_id     :integer
#  created_at         :datetime
#  updated_at         :datetime
#  filtering_field_id :integer
#  original_id        :integer
#
