class Extra < ActiveRecord::Base
  require 'csv'

  extend EnumerateIt

  attr_protected :id, :created_at, :updated_at
  has_enumeration_for :field_type, :with => ExtraFieldType, :required => true, :create_helpers => true

  has_many :item_extras, :dependent => :destroy
  has_many :loop_item_names, :through => :item_extras
  belongs_to :loop_item_type
  has_many :question_extras, :dependent => :destroy
  has_many :questions, :through => :question_extras
  has_many :section_extras, :dependent => :destroy
  has_many :sections, :through => :section_extras

  def handle_source file_path, status
    status[:line] = 0

    # get the default language of the questionnaire
    default_lang = self.loop_item_type.root.loop_source
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
         :encoding => "`Uâ€™"
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
        the_litem_name = row_as_a[0][1].squeeze(" ").strip
        item_name_utf8 = the_litem_name.force_encoding("ISO-8859-1").encode("UTF-8")

        # check if there's a loop_item_names with the value of the first column of each row
        loop_item_name_field = self.loop_item_type.loop_item_name_fields.find_by_item_name_and_language(item_name_utf8.to_s, default_lang)#row_as_a[0][1])
        loop_item_name = loop_item_name_field.present? ? loop_item_name_field.loop_item_name : nil

        # if not, return with info about the error
        if !loop_item_name
          status[:errors] << "ERROR: Line number #{status[:line]}. There is no loop item by the name of: #{item_name_utf8}"

          # ignore the lines that don't exist
          next
          # return false
        else
          # otherwise  find (if it's updating) or create and store the new item_extras object
          item_extras_obj = self.item_extras.find_or_create_by_loop_item_name_id(loop_item_name.id)
        end

        # remove the first column
        row_as_a.delete_at(0)

        # add the extra_fields to the item_extras object. Storing the language
        row_as_a.each_index do |i| #row_as_a[i][0] => header; row_as_a[i][1] => value
          the_lang = row_as_a[i][0].squeeze(" ").strip
          the_extra_val = row_as_a[i][1].squeeze(" ").strip
          if the_extra_val.present? #if there's no name, there's no item

            # check if  there's already a item_extra_field with the current language:  if not, create it and then update the values.
            item_extra_field = item_extras_obj.item_extra_fields.find_or_create_by_language(the_lang)#lang_utf8.to_s)#
            item_extra_field.is_default_language = (default_lang == the_lang)#lang_utf8.to_s)#
            item_extra_field.value = the_extra_val
            begin
              item_extra_field.save!
            rescue
              #cd = CharDet.detect(the_extra_val)
              item_extra_field.value = the_extra_val.force_encoding("ISO-8859-1").encode("UTF-8").to_s
              if !item_extra_field.save!
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
      header_loop_type = header_row[0].dup
      header_loop_type.slice!(0)
      if header_loop_type.squeeze(" ").strip.downcase != self.loop_item_type.name.squeeze(" ").strip.downcase
        status[:errors] << "ERROR: Header row. First element must be the type of the loop items."
        return false
      else
        header_row.delete_at(0)
      end
      languages = self.loop_item_type.root.loop_source.questionnaire.questionnaire_fields.map{ |a| a.language }
      header_row.each do |header|
        if !header || !languages.include?(header.squeeze(" ").strip)
          status[:errors] << "ERROR: Header row. The characteristic values can only be defined in the languages of the questionnaire. (#{languages.join(', ')})."
          return false
        end
      end
    end
    true
  end

end

# == Schema Information
#
# Table name: extras
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  loop_item_type_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#  field_type        :integer
#  original_id       :integer
#
