class QuestionnairePart < ActiveRecord::Base
  attr_accessible :questionnaire_id, :part_id, :part_type, :parent_id, :lft, :rgt

  ###
  ###   Plugins/Gems declarations
  ###
  acts_as_nested_set :dependent => :destroy

  ###
  ###   Relationships
  ###
  belongs_to :questionnaire
  belongs_to :part, :polymorphic => true
  accepts_nested_attributes_for :part, :reject_if => lambda { |a| a.values.all?(&:blank?) }

  ###
  ###   Methods
  ###

  def propagate_languages_changes(langs_to_remove, langs_to_add, new_default )
    self.self_and_descendants.map(&:part).each do |part|
      part.propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
    end
  end

  def destroy_branch
    self.children.each do |child|
      child.destroy_branch
    end
    if self.part.present?
      self.part.destroy
    end
    self.delete
  end

  def build_part_from_params params, questionnaire
    self.part = params[:part_type].classify.constantize.new
    questionnaire.questionnaire_fields.each do |field|
      self.part.send(params[:part_type].underscore+"_fields").build( :language => field.language, :is_default_language => field.is_default_language )
    end
  end

  #methods to help generate the tree structure with the sections and questions under a questionnaire
  def self.add_children_info(kids, params)
    @carray = []
    kids.sort! { |a,b| a.lft <=> b.lft }.each do |child|
      ch2 = child.children
      the_title = Sanitize.clean(child.display_title).strip.gsub("\n\n", "")
      @carray += [ {
              :title => the_title[0,25] + (the_title.size > 25 ? "..." : ""),
              :tooltip => the_title,
              :isFolder => child.part.is_a?(Section),
              :key => child.part.is_a?(Section) ? child.part_id.to_s : "q"+ child.part_id.to_s,
              :expand => false,
              :activate => ( params[:activate] && params[:activate].to_i == child.part_id ) ? true : false,
              :children => ch2.empty? ? [] : QuestionnairePart.add_children_info(ch2, params)
      } ]
    end
    @carray
  end

  #methods to help generate the tree structure with the sections and questions under a questionnaire
  def self.add_children_info_to_jstree(kids, params, looping_branch)
    carray = []
    kids.sort! { |a,b| a.lft <=> b.lft }.each do |child|
      is_movable = child.part_is_movable?
      looping_branch = looping_branch || (child.part.is_a?(Section) && child.part.loop_source.present?)
      part_is_section = child.part.is_a?(Section)
      ch2 = child.children
      the_title = Sanitize.clean(child.display_title).strip.gsub("\n\n", "")
      carray += [ {
              :data => {
                      :title => the_title[0,150] + (the_title.size > 150 ? "..." : ""),
                      :icon => part_is_section ? "folder" : "/assets/dynatree/ltDoc.gif"
              },
              #:tooltip => the_title,
              #:isFolder => child.part.is_a?(Section),
              #:key => child.part.is_a?(Section) ? child.part_id.to_s : "q"+ child.part_id.to_s,
              :attr => {:id => child.id.to_s, :movable => is_movable.to_s, :targetable => part_is_section.to_s,
                         :is_question => (!part_is_section).to_s, :looping_branch => looping_branch,
                         :display_in_tab => (child.part.is_a?(Section) && !child.root? && child.part.display_in_tab?)},
              :state => part_is_section && ch2.present? ? "closed" : "leaf",
              #:activate => ( params[:activate] && params[:activate].to_i == qpart.part_id ) ? true : false,
              :children => ch2.empty? ? [] : QuestionnairePart.add_children_info_to_jstree(ch2, params, looping_branch)
      } ]
    end
    carray
  end

  def display_title
    self.part.is_a?(Question) ? self.part.title : self.part.tab_title.present? ? self.part.tab_title : self.part.title
  end

  def children_parts_sorted
    #self.children.find(:all, :include => :part).sort.map{|a| a.part}
    self.children.find(:all, :include => :part, :order => "lft ASC").map{ |a| a.part }
  end

  def part_is_movable?
    the_part = self.part
    if the_part.is_a?(Question)
      return !the_part.loop_item_types.present? && !the_part.extras.present?
    end
    !the_part.loop_source.present? && !the_part.extras.present?
  end
end

# == Schema Information
#
# Table name: questionnaire_parts
#
#  id               :integer          not null, primary key
#  questionnaire_id :integer
#  part_id          :integer
#  part_type        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  lft              :integer
#  rgt              :integer
#  original_id      :integer
#
