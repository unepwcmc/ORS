class LoopSource < ActiveRecord::Base
  ###
  ###   Required Files
  ###
  require 'digest/md5'
  require 'csv'

  #attr_accessible :name, :deleted, :questionnaire_id
  attr_protected :id

  before_destroy :destroy_loop_item_types

  validates :name, presence: true

  ###
  ###   Relationships
  ###
  has_one :loop_item_type, dependent: :destroy
  has_many :sections, :dependent => :nullify
  belongs_to :questionnaire
  has_many :loop_item_names, dependent: :destroy
  #submission side of the tool
  has_many :source_files, :dependent => :destroy
  accepts_nested_attributes_for :source_files, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  ###
  ###   Methods
  ###

  def unparsed_sources?
    self.source_files.find_by_parse_status(ParseFileStatus::TO_PARSE)
  end

  # load the loop_items of a loop_source from a file.
  def parse_file status, source_file_obj
    existing_structure = self.loop_item_type.present?

    # keep track of the errors
    status[:errors] = []

    # keep track of the line and column being analised, for error reporting.
    status[:line] = 0
    status[:column] = 0

    # save the headers and the items
    status[:headers] = []
    status[:items] = []

    # auxiliar hash, to avoid repetition
    created_items = {}

    # read the file into a table
    begin
      if File.open(source_file_obj.source.path, &:readline).match(/;/) == nil
        separator = ','
      else
        separator = ';'
      end

      table = CSV.read(source_file_obj.source.path, {
        :quote_char =>'"',
        :col_sep =>separator,
        :row_sep =>:auto,
        :headers => :first_row
      })
    rescue => e
      status[:errors] << e.message
      return false
    end
    #get the headers
    status[:headers] = table.headers
    item_types = {}

    if !self.parse_source_headers(status, item_types, existing_structure)
      return false
    end

    default_language = self.questionnaire
      .questionnaire_fields
      .find_by_is_default_language(true)
      .language

    table.each do |row|
      status[:line] += 1

      # Start with parent as nil (because the first element of each line is the root of the nested set, and looping structure)
      # there is also an hierarchy between items.
      parent = nil

      # and then for each item of the row
      row_as_a = row.to_a

      row_as_a.each_index do |i| # row_as_a[i][0] => item_type ; row_as_a[i][1] => loop_item_names
        created_items[i.to_s] ||= {}

        if row_as_a[i][1].present? # if there's no name, there's no item
          the_val = row_as_a[i][1].squeeze(" ").strip
          the_type = row_as_a[i][0].squeeze(" ").strip
          the_type.slice!(0) if the_type[0] == '#'
          status[:column] += 1

          if existing_structure && (existing_item=(item_types[the_type].existing_item_with(the_val, parent, default_language)))
            parent = existing_item
            next
          end

          # loop_item_names in downcase for comparison purposes. So that the file doesn't need to be case sensitive.
          item_details = {:name => the_val.downcase, :parent => parent.nil? ? "parent_empty" : parent.id}
          item_hash = Digest::MD5.hexdigest(item_details.to_s)

          # check if item was previously added
          if created_items[i.to_s][item_hash]
            #set this item as the parent
            parent = LoopItem.find(created_items[i.to_s][item_hash])
          else # otherwise create a new item
            son = LoopItem.new()#:item_name => row_as_a[i][1].to_s)
            son.loop_item_type_id = item_types[the_type].id
            # set it's parent, if parent is defined, otherwise it will be a root item.
            if parent
              son.parent = parent
            end

            # handle loopItemNames. Find or create it and then add it to the loop_item and loop_item_type and loop_source
            begin
              l_item_name = item_types[the_type].loop_item_name_with(the_val, default_language, self)
            rescue ActiveRecord::RecordInvalid => e
              status[:errors] << "ERROR: line #{status[:line]} and column #{status[:column]}. Check the character encoding of your file."
              next
            end
            son.loop_item_name = l_item_name

            # set sort_index => total loop_items before adding the new item to it, so that it is the index of the total of items[0 to total]
            # son.sort_index = item_types[the_type].loop_items.count #set the sort_index to be one more than the parent's. The default is zero, so the parent starts at zero.
            son.sort_index = item_types[the_type].loop_items.empty? ? 0 : item_types[the_type].loop_items.maximum("sort_index") + 1

            # save the son
            if son.save
              #add the item to the hash of created items
              created_items[i.to_s][item_hash] = son.id
              status[:items] << son

              #redefine the parent for next iteration
              parent = son
            else
              status[:errors] << "Problem in line " + status[:line] + ", and column " + status[:column]
              return false
            end
          end
        end
      end

      status[:column] = 0
    end
  end

  def parse_source_headers status, item_types, existing_structure
    #check if headers are present: Headers/Title line should start with "#"
    if !['#'].include?(status[:headers][0].to_s[0,1]) && "\357" != status[:headers][0].to_s[0,1]
      status[:errors] << "Header row is not properly defined. Should start with a '#' character."
      return false
    end
    #remove the '#' character, since it is no longer needed
    status[:headers][0] = status[:headers][0].slice(1, status[:headers][0].length - 1)
    if !existing_structure
      self.create_new_structure(status, item_types )
    else
      self.matching_structure?(status, item_types)
    end
  end

  def matching_structure?(status, item_types)
    self.loop_item_type.self_and_descendants.sort.each do |descendant|
      if status[:headers][descendant.level].squeeze(" ").strip != descendant.name.squeeze(" ").strip
        status[:errors] << "Header row does not match the existing structure of this loop source. Mismatch: #{status[:headers][descendant.level]} != descendant.name"
        return false
      end
      item_types.merge!(descendant.name => descendant)
    end
    true
  end

  def create_new_structure(status, item_types)
    puts "add the item_types to the database"
    header_parent = nil
    status[:headers].each do |header|
      if !header
        status[:errors] << "Error in the header line, please check your file."
        return false
      else
        puts "new item_types"
        item_type = LoopItemType.new(:name => header.squeeze(" ").strip)
        if header_parent
          item_type.parent = header_parent
        else
          #associated first item_type with the loop_source | the next item types will be descendants of the first
          # to keep the hierarchy between item types
          item_type.loop_source = self
        end
        begin
          puts "saving item_types"
          item_type.save
        rescue => e
          puts "error zone 1 #{e}"
          item_type.name = header.force_encoding("ISO-8859-1").encode("UTF-8").to_s.squeeze(" ").strip
          if !item_type.save!
            puts "error zone 2"
            status[:errors] << header + ": Please check the character encoding of your file."
            return false
          end
        end
        item_types.merge!(item_type.name => item_type)
        header_parent = item_type
      end
    end
    true
  end

  #get the available item types for this section
  def self.get_item_types(params)
    loop_source = LoopSource.find(params[:id])
    @loop_types = loop_source.loop_item_type
  end

  def update_sections
    self.sections.each do |section|
      section.section_type = SectionType::REGULAR
      section.loop_source = nil
      section.save!
    end
  end

  def fill_jqgrid grid_details, params
    grid_details[:rows] = []
    if params[:sord].present? && params[:sidx].present?
      sorting_type = self.loop_item_type.self_and_descendants.find_by_name(params[:sidx])
      the_items = sorting_type.leaf_loop_items_sorted(params)
    else
      the_items = self.loop_item_type.leaf? ? self.loop_item_type.loop_items : self.loop_item_type.leaves.map{ |a| a.loop_items }.flatten
    end
    grid_details[:total_records] = the_items.size
    first_index = ((params[:page].to_f-1.0)*params[:rows].to_f).ceil
    last_index = (params[:rows].to_f * params[:page].to_f).ceil
    cells = []
    the_items[first_index, last_index].each do |loop_item|
      cells << loop_item.fill_jqgrid
    end
    if params[:_search] == "true"
      search_level = self.loop_item_type.self_and_descendants.find_by_name(params[:searchField]).level
      cells = LoopSource.parse_search(cells, search_level+1, params[:searchString], params[:searchOper], params[:language])
    end
    cells.each do |cell|
      grid_details[:rows] << {:cell => cell.map{ |a| (a.is_a?(LoopItem) ? a.item_name(params[:language]) : a) }}
    end
    grid_details[:total_pages] = (grid_details[:total_records].to_f/params[:rows].to_f).ceil
  end

  def update_records params
    default_lang = self.questionnaire.questionnaire_fields.find_by_is_default_language(true).language
    leaf_item = LoopItem.find(params[:leaf_id], :include => [:loop_item_name, :loop_item_type])
    lang_code = params[:language]
    leaf_item.self_and_ancestors.each do |loop_item|
      if loop_item.item_name(lang_code) != params[loop_item.loop_item_type.name.to_sym]
        loop_item.update_name_from params, lang_code, default_lang
      end
    end
  end

  def delete_record params
    params[:leaf_id].each do |leaf_id|
      leaf = LoopItem.find(leaf_id)
      loop_items_to_destroy = []
      if leaf
        loop_items_to_destroy << leaf
        #delete only items that do not have other descendants
        leaf.ancestors.reverse.each do |ancestor|
          if ancestor.descendants.size <= 1
            loop_items_to_destroy << ancestor
          else
            break
          end
        end
        loop_items_to_destroy.sort{ |a,b| b.lft <=> a.lft }.each do |item|
          item.destroy
          if item.loop_item_name.loop_items.size <= 1
            item.loop_item_name.destroy
          end
        end
      end
    end
  end

  def self.parse_search(cells, search_index, search_string, operator, language)
    cells.reject{ |a| a[search_index].not_a_match?(operator, search_string, language) }
  end

  def delete_smoothly
    if self.loop_item_type
      self.loop_item_type.self_and_descendants.each do |litem_type|
        litem_type.loop_items.each do |loop_item|
          loop_item.delete
        end
        litem_type.loop_item_names.each do |item_name|
          item_name.loop_item_name_fields.each do |lfield|
            lfield.delete
          end
          item_name.delete
        end
        litem_type.extras.each do |extra|
          extra.item_extras.each do |item_extra|
            item_extra.delete
          end
          extra.question_extras.each do |q_extra|
            q_extra.delete
          end
          extra.section_extras.each do |s_extra|
            s_extra.delete
          end
        end
        litem_type.delete
      end
    end
    self.delete
  end

  private

  def destroy_loop_item_types
    if self.loop_item_type.present?
      self.loop_item_type.destroy
    end
  end
end

# == Schema Information
#
# Table name: loop_sources
#
#  id               :integer          not null, primary key
#  name             :text             not null
#  questionnaire_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  original_id      :integer
#
