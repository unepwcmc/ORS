class Delegation < ActiveRecord::Base

  attr_protected :id

  belongs_to :user_delegate
  has_one :user, :through => :user_delegate
  has_one :delegate, :through => :user_delegate
  belongs_to :questionnaire, :include => :questionnaire_fields
  has_many :delegation_sections, :dependent => :destroy, :include => [:section, {:delegated_loop_item_names => {:loop_item_name => :loop_item_name_fields}} ]
  has_many :sections, :through => :delegation_sections, :include => :section_fields
  has_many :delegated_loop_item_names, :through => :delegation_sections
  has_many :loop_item_names, :through => :delegated_loop_item_names, :include => :loop_item_name_fields

  attr_accessible :questionnaire_id, :user_delegate_id, :can_view_all_questionnaire,
    :from_submission, :remarks

  validates :questionnaire_id, presence: true
  validates_uniqueness_of :questionnaire_id, scope: :user_delegate_id

  def can_view_only_assigned_sections?
    !self.can_view_all_questionnaire && !self.delegation_sections.empty?
  end

  def can_view_and_edit_all_questionnaire?
    self.delegation_sections.empty?
  end

  def available_sections
    return [] unless self.questionnaire
    #FIXME: Should make this into a SQL query to make it faster.
    #start by fetching the delegate's tasks that are of type "Section" and that belong to questionnaire
    previously_delegated_sections = self.sections.map{|section|
      section.self_and_descendants
    }.flatten
    #get all the sections (questionnaire_parts.part of type Section) that belong to the delegator's available questionnaire.
    #reject the sections that are already part of the delegate's tasks.
    self.questionnaire.questionnaire_parts.map{|questionnaire_part|
      questionnaire_part.self_and_descendants
    }.flatten.map{|quest_part|
      quest_part.part
    }.reject{|part|
      !part.is_a?(Section) || previously_delegated_sections.include?(part)
    }.sort{ |a,b| a.lft <=> b.lft }
  end

  def available_sections_including section
    return [] unless self.questionnaire
    sections_unavailable = self.sections - Array(section)
    #start by fetching the delegate's tasks that are of type "Section" and that belong to questionnaire
    previously_delegated_sections = sections_unavailable.reject{ |s| s.nil? }.map{|s|
      s.self_and_descendants
    }.flatten
    #get all the sections (questionnaire_parts.part of type Section) that belong to the delegator's available questionnaire.
    #reject the sections that are already part of the delegate's tasks.
    #FIXME: Should make this into a SQL query to make it faster.
    self.questionnaire.questionnaire_parts.map{|questionnaire_part|
      questionnaire_part.self_and_descendants
    }.flatten.map{|quest_part|
      quest_part.part
    }.reject{|part|
      !part.is_a?(Section) || previously_delegated_sections.include?(part)
    }.sort{ |a,b| a.lft <=> b.lft }
  end

  def self.available_questionnaires_for delegate, delegator
    previously_delegated_questionnaires = delegate.delegated_tasks.map{ |delegation| delegation.questionnaire if delegation.delegation_sections.empty? }
    delegator.available_questionnaires.reject{|quest|
      previously_delegated_questionnaires.include?(quest) || delegate.available_questionnaires.include?(quest)
    }
  end

  def add_details_from params
    self.task_id = params[:delegation][:task_type] == "Section" ? params[:section_id].to_i : params[:questionnaire][:id]
    if params[:delegation][:task_type] == "Section" && params[:section_loop_item_names]
      params[:section_loop_item_names].each do |item_name_id|
        item_name = LoopItemName.find(item_name_id)
        if item_name
          self.delegated_loop_item_names << DelegatedLoopItemName.create(:loop_item_name => item_name)
        end
      end
    end
  end

  def remove_overlapping_tasks
    #if the newly added task is a section, there won't be a new collision
    return false if self.task.is_a?(Section)
    questionnaire = self.task
    delegator = self.user
    delegate = self.delegate
    #get all the delegations that belong to the delegator/delegate pair
    delegations = delegator.delegations.find_all_by_delegate_id(delegate.id)
    #reject the questionnaires
    possible_collisions = delegations.reject{ |delegation| delegation.task.is_a?(Questionnaire) }
    #check if the existing tasks belong to the questionnaire, if so remove them , otherwise they'll overlap
    possible_collisions.each do |delegation|
      if delegation.task && delegation.task.questionnaire == questionnaire
        delegation.delete
      end
    end
  end

  #get an array of existing delegations of the given delegator
  #that do not cover (have no section that is or is ancestor of 'section') the given section
  def self.delegates_not_yet_delegated delegator, section, loop_item_name_id=nil
    questionnaire = section.questionnaire
    user_delegates = delegator.user_delegates
    result = []
    user_delegates.each do |user_delegate|
      existing_delegation = user_delegate.delegations.find_by_questionnaire_id(section.questionnaire.id)
      if (!existing_delegation || !existing_delegation.delegation_sections.any? || !(Delegation.covers_section?(existing_delegation, section, loop_item_name_id))) && !user_delegate.delegate.available_questionnaires.include?(questionnaire)
        result << user_delegate
      end
    end
    result
  end

  def self.covers_section?(delegation, section, loop_item_name_id=nil)
    return false if !delegation
    return true if !delegation.sections.any?
    delegation.delegation_sections.each do |delegated_section|
      if delegated_section.section.is_or_is_ancestor_of?(section)
        #covers_section = true
        if !loop_item_name_id || delegated_section.loop_item_names.map(&:id).include?(loop_item_name_id.to_i)
          return true
        end
      end
    end
    false
  end
end

# == Schema Information
#
# Table name: delegations
#
#  id                         :integer          not null, primary key
#  created_at                 :datetime
#  updated_at                 :datetime
#  remarks                    :text
#  questionnaire_id           :integer
#  user_delegate_id           :integer
#  from_submission            :boolean
#  original_id                :integer
#  can_view_all_questionnaire :boolean          default(FALSE)
#
