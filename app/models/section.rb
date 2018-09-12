class Section < ActiveRecord::Base
  ###
  ###   Include Libs
  ###
  include LanguageMethods
  include SectionDependencies
  include SectionsAndQuestionsShared
  include SectionNestedThrough
  include SectionBranchMethods
  include SectionSaveAnswers
  extend EnumerateIt

  #attr_accessible :is_hidden, :section_type, :questionnaire_id, :parent_id, :answer_type_id, :answer_type_type, :loop_source_id, :loop_item_type_id, :section_fields_attributes, :starts_collapsed
  attr_protected :id, :created_at, :updated_at
  attr_accessor :section_extras_ids
  has_enumeration_for :section_type, :with => SectionType, :required => true, :create_helpers => true

  before_save :coherence_of_type
  after_save :update_section_extras
  before_destroy :destroy_answer_type

  ###
  ###   Plugins/Gems declarations
  ###
  #acts_as_nested_set :dependent => :destroy

  ###
  ###   Relationships
  ###

  has_one :questionnaire_part, :as => :part
  has_many :questions, :dependent => :destroy, :include => :question_fields
  belongs_to :loop_source
  belongs_to :loop_item_type
  #For same_answer_type type of sections
  belongs_to :answer_type, :polymorphic => true
  #submission side of the tool
  #section can depend on a specific option of a question being selected
  belongs_to :depends_on_option, :class_name => "MultiAnswerOption"
  belongs_to :depends_on_question, :class_name => "Question"
  has_many :section_fields, :dependent => :destroy #=> to allow for multiple languages.
  accepts_nested_attributes_for :section_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  #=> for each user the state of completion of a section will be stored
  has_many :submission_states, :class_name => "UserSectionSubmissionState", :dependent => :destroy
  has_many :section_extras, :dependent => :destroy
  has_many :extras, :through => :section_extras
  has_many :delegation_sections, dependent: :destroy
  has_many :delegations, :through => :delegation_sections
  has_one :csv_file, :dependent => :destroy, :as => :entity

  #Section Types Information
  # section_type: 0 - looping section
  # section_type: 1  - section with a defined answer type
  # section_type: 2  - regular section

  ###
  ###   Validations
  ###
  validates_presence_of :section_type
  validates_associated :section_fields

  ###
  ###   Methods
  ###

  def self.section_update_from(params)
    section = Section.find(params[:id], :include => :answer_type)
    if ( section.section_type.to_s != params[:part][:section_type] ) && section.has_answers?
      section.remove_submission_elements!
    end
    if params[:answer_type]
      #if section_type of a section is != of 1, it means that there is no "answer_type" for that section.
      if section.section_type != 1 || params[:part][:answer_type_type].classify.constantize != section.answer_type.class
        #If the class of the answer_type being passed is different from the one associated with the section
        # it is necessary to destroy the old answer_type and create a new one for the section
        answer_type = params[:part][:answer_type_type].classify.constantize.new(params[:answer_type])
        answer_type.save! if answer_type
        section.answer_type = answer_type #not destroying previous answer_type, because it might be in use somewhere.
      else
        #otherwise simply update the answer_type
        section.answer_type.update_attributes(params[:answer_type])
      end
      section.questions.each do |question|
        question.answer_type = section.answer_type #update the answer_type in the questions to match the section!
        question.save!
      end
    else
      #if no answer_type is passed, it is necessary to remove the old answer_type, if it exists
      if section.section_type == 1
        #@section.answer_type.delete #not destroying previous answer_type, because it might be in use somewhere.
        section.answer_type = nil
      end
    end
    section
  end

  def self.create_section_from(params)
    if params[:answer_type] && params[:answer_type].present?
      answer_type = params[:part][:answer_type_type].classify.constantize.new(params[:answer_type])
      answer_type.save! if answer_type
      section = answer_type.sections.build(params[:part])
    else
      params[:part].delete(:answer_type_type)
      section = Section.new(params[:part])
      section.answer_type = nil
    end
    section
  end

  #check if the loop_source of a section and of a loop_item_type match.
  def matching_loop_sources?(loop_item_type)
    (self.loop_source.nil? ? false : (self.loop_source == (loop_item_type.root? ? loop_item_type.loop_source : loop_item_type.root.loop_source)))
  end

  def first_ancestor_item_type(loop_item_type)
    if self.matching_loop_sources?(loop_item_type)
      self.loop_item_type
    else
      (self.parent.nil? || self.parent.id == self.id) ? nil : self.parent.first_ancestor_item_type(loop_item_type)
    end
  end

  def descendant_item_type(loop_item_type)
    item_type = nil
    self.descendants.each do |descendant|
      if descendant.matching_loop_sources?(loop_item_type)
        item_type = descendant.loop_item_type if !item_type || item_type.is_descendant_of?(descendant.loop_item_type)
      end
    end
    item_type
  end

  #Function to check if any of the section's questions has answers associated
  def has_answers?
    self.questions.each do |question|
      if question.answers.present?
        return true
      end
    end
    false
  end

  def has_parent?
    self != self.root
  end

  def parent
    self.root
  end

  def is_delegated_to?(delegation)
    self.delegations.include?(delegation)
  end

  def is_or_has_parents_delegated_to?(delegation)
    delegations = []
    self.self_and_ancestors.each do |parent|
      delegations << parent.delegations
    end

    delegations.flatten.include?(delegation)
  end

  def sections_delegated_to(delegation)
    self.descendants.select { |c| c.is_delegated_to?(delegation) }
  end

  def has_sections_delegated_to?(delegation)
    self.sections_delegated_to(delegation).any?
  end

  #check if the id of the generated_section is part of an hash of hidden dependent sections and if its value is one (meaning that its hidden
  #and its associated answers should be destroyed.
  def marked_as_hidden?(hidden_hash, loop_item_id=nil)
    loop_items_ids = []
    if loop_item_id
      Array(loop_item_id).each do |item_id|
        if hidden_hash.include?(self.id.to_s + (item_id ? "_#{item_id}" : "")) && hidden_hash[self.id.to_s + (item_id ? "_#{item_id}" : "")] == "1"
          loop_items_ids << loop_item_id
        end
      end
      return loop_items_ids if loop_items_ids.present?
    else
      hidden_hash.include?(self.id.to_s) && hidden_hash[self.id.to_s] == "1"
    end
    false
  end

  #
  # @param [Hash] dependent_sections_state hash with keys: section_id_looping_identifier; values: visibility (1:hidden; 0:visible)
  # @param [User] user
  def self.dependent_availability_changes dependent_sections_state, user
    dependent_sections_state.each do |identifiers, val|
      section_id, looping_identifier = identifiers.split("_")
      looping_identifier = nil if "0" == looping_identifier
      s = Section.find(section_id)
      next if !s
      if val == "1"
        s.destroy_related_answers!(user, looping_identifier)
      elsif val == "0"
        s.update_submission_state_to_care(user, looping_identifier)
      end
    end
  end

  # This method goes through a section and its descendants questions and removes the existing answers.
  # It then sets those sections submission state to dont_care, so that they are overlooked by the Root Section when calculating the Root Section Submission state
  #
  # @param [User] user
  # @param [Intenger] looping_identifier associated with the section being saved
  def destroy_related_answers!(user, looping_identifier=nil)
    with_current_l_identifier = self.self_and_descendants
    looping = self.looping_descendants
    if !looping.empty?
      if looping_identifier.present?
        all_l_descendants = looping.map{ |s| s.self_and_descendants }.flatten
        with_current_l_identifier = with_current_l_identifier - all_l_descendants
        Answer.destroy_all("question_id IN (#{all_l_descendants.map{ |s| s.questions.map{ |q| q.id } }.flatten.join(',')}) AND user_id = #{user.id} AND looping_identifier iLIKE '#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}%'")
        UserSectionSubmissionState.update_all({:dont_care => false}, "section_id IN (#{all_l_descendants.map{ |s| s.id }.join(',')}) AND user_id = #{user.id} AND looping_identifier iLIKE '#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}%'")
        Answer.destroy_all({:question_id => with_current_l_identifier.map{ |s| s.questions.map{ |q| q.id } }.flatten, :user_id => user.id, :looping_identifier => looping_identifier})
        UserSectionSubmissionState.update_all({:dont_care => true}, {:section_id => with_current_l_identifier.map{ |s| s.id }, :user_id => user.id, :looping_identifier => looping_identifier})
      else
        Answer.destroy_all({:question_id => with_current_l_identifier.map{ |s| s.questions.map{ |q| q.id } }.flatten, :user_id => user.id})
        UserSectionSubmissionState.update_all({:dont_care => true}, {:section_id => with_current_l_identifier.map{ |s| s.id }, :user_id => user.id})
      end
    else
      Answer.destroy_all({:question_id => with_current_l_identifier.map{ |s| s.questions.map{ |q| q.id } }.flatten, :user_id => user.id, :looping_identifier => looping_identifier})
      UserSectionSubmissionState.update_all({:dont_care => true}, {:section_id => with_current_l_identifier.map{ |s| s.id }, :user_id => user.id, :looping_identifier => looping_identifier})
    end
  end

  # Set section and descendants sections' Submission state to care (dont_care = false). To be considered in the root submission state.
  # The method will go through the section descendants using the looping_identifier, if it exists, but stops using it if it comes across a looping section, as the
  # looping_identifier would be different. If the method finds a section that is dependent it will break, as there's no way to know if that section is available or not.
  #
  # @param [User] user
  # @param [String] looping_identifier looping_identifier relative to the section the state is being updated
  def update_submission_state_to_care user, looping_identifier=nil
    #UserSectionSubmissionState.update_all({:dont_care => false}, {:section_id => self.id, :user_id => user.id, :looping_identifier => looping_identifier})
    if (dependent = self.dependent_descendants)
      to_update = self.self_and_descendants - dependent.map{ |d| d.self_and_descendants }.flatten
    else
      to_update = self.self_and_descendants
    end
    l_descendants = self.looping_descendants
    if !l_descendants.empty?
      if looping_identifier.present?
        all_l_descendants = l_descendants.map{ |s| s.self_and_descendants }.flatten
        to_update = to_update - all_l_descendants
        UserSectionSubmissionState.update_all({:dont_care => false}, "section_id IN (#{all_l_descendants.map{ |s| s.id }.join(',')}) AND user_id = #{user.id} AND looping_identifier iLIKE '#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}%'")
        UserSectionSubmissionState.update_all({:dont_care => false}, {:section_id => to_update.map{ |s| s.id }, :user_id => user.id, :looping_identifier => looping_identifier})
      else
        UserSectionSubmissionState.update_all({:dont_care => false}, {:section_id => to_update.map{ |s| s.id }, :user_id => user.id})
      end
    else
      UserSectionSubmissionState.update_all({:dont_care => false}, {:section_id => to_update.map{ |s| s.id }, :user_id => user.id, :looping_identifier => looping_identifier})
    end
  end

  # Method to create the UserSectionSubmissionState records for this section's tree to accurately keep track of questionnaire submission
  # Sets sections with questions with submission_state of unanswered.
  # Sets sections with no questions with submission_state of new.
  #
  # @param [User] user
  # @param [Hash] loop_sources_items keeps track of the loop_item that was last used in this recursive method, for each loop_source
  # @param [LoopItem] loop_item
  # @param [Boolean] dont_care_descendants We want that sections that are under a dependent section are also disregarded when the dependency is not met. So we pass along the parent dont_care value.
  def initialise_tree_submission_states user, loop_sources_items, loop_item=nil, dont_care_descendants=false, looping_identifier=nil
    state_tracker = UserSectionSubmissionState.find_or_initialize_by_section_id_and_user_id_and_looping_identifier(self.id, user.id, looping_identifier)
    #dont_care_descendants = dont_care_descendants || (self.depends_on_question.present? && !self.dependency_condition_met?(user, loop_item))
    if state_tracker.new_record?
      if self.root?
        state_tracker.section_state = 4
      elsif self.questions.any?
        state_tracker.section_state = self.questions.find_by_is_mandatory(true) ? 1 : 0
      end
      #for new state_tracker: don't care if dont_care_descendants == true, or if it depends on a question's option being selected.
      dont_care_descendants = dont_care_descendants || (self.depends_on_question.present? && self.depends_on_option_value?)
    else
      dont_care_descendants = dont_care_descendants || (self.depends_on_question.present? && !self.dependency_condition_met?(user, looping_identifier))
      state_tracker.section_state = self.questions_answered_status(user, looping_identifier)
    end
    state_tracker.dont_care = dont_care_descendants
    state_tracker.save if state_tracker.changed?
    self.children.each do |s|
     if s.looping?
       items = s.next_loop_items(loop_item, loop_sources_items) || []
       items.each do |item|
         if s.available_for? user, item
           loop_sources_items[s.loop_source.id.to_s] = item
           new_looping_identifier = looping_identifier.present? ? "#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}#{item.id}" : item.id.to_s
           s.initialise_tree_submission_states user, loop_sources_items, item, dont_care_descendants, new_looping_identifier
         end
       end
     else
       s.initialise_tree_submission_states user, loop_sources_items, loop_item, dont_care_descendants, looping_identifier
     end
    end
  end

  # Update the submission state of the root of the section tree for this section and a specific user and looping_identifier (if it exists)
  # It will fetch this section's state and its descendants (the one with questions) states and then analyse which state should the root have, to
  # accurately reflect the state of the whole tree.
  #
  # @param [User] user User for which to update this root section status
  # @param [Integer] looping_identifier looping_identifier associated with the section. As the section can be saved multiple times for different LoopItems. LoopItem can be nil if self is not looping
  def update_root_submission_state!(user, looping_identifier=nil)
    if self.questions.any?
      self.update_submission_state!(user, looping_identifier)
    end
    state_tracker = UserSectionSubmissionState.find_or_create_by_user_id_and_section_id_and_looping_identifier(user.id, self.id, looping_identifier)
    all_states = user.submission_states.find(:all, :conditions => {:section_id => self.self_and_descendants.reject{ |s| !s.questions.any? }.map{ |s| s.id }.flatten, :dont_care => false}, :select => :section_state).map{ |sub| sub.section_state }.uniq.sort
    #state is only 0 (all unanswered) or 3(all answered) if there are no other states
    #if there's state 1 (mandatory unanswered) return 1 otherwise return 2 (mandatory answered, and other answers exist, but still there answeres missing
    status = if all_states.size == 1
      all_states.first
    elsif all_states.include?(1)
      1
    elsif all_states.include?(2) || (all_states.include?(0) && all_states.include?(3))
      2
    else
      all_states.min
    end
    state_tracker.update_attribute(:section_state, status)
  end

  def update_submission_state!(user, looping_identifier=nil)
    state_tracker = UserSectionSubmissionState.find_or_create_by_user_id_and_section_id_and_looping_identifier(user.id, self.id, looping_identifier)
    status = self.questions_answered_status(user, looping_identifier)
    state_tracker.update_attribute(:section_state, status)
  end

  #check the answered status for a specific question for a user
  def questions_answered_status(user, looping_identifier=nil) # 0 = none answered, 1 = mandatory unanswered, 2 = mandatory answered, 3 = all answered,
    #return 4 if self.questions.count == 0 #if the section has no questions, treat it as a brand new
    #if the section is not visible, because the dependency conditions for it are not met
    # treat as a brand new  section.
    return 4 if (self.depends_on_question && !self.dependency_condition_met?(user, looping_identifier)) || !self.questions.any?
    mandatory_unanswered = false
    some_unanswered = false
    at_least_one_answered = false
    self.questions.each do |question|
      if question.answered_status(user, looping_identifier)
        at_least_one_answered = true
      else
        if question.is_mandatory
          mandatory_unanswered = true
          break
        else
          some_unanswered = true
        end
      end
    end
    if mandatory_unanswered #mandatory not answered
      return 1
    elsif !at_least_one_answered #none answered
      return 0
    elsif !mandatory_unanswered && !some_unanswered #All Answered
      return 3
    end
    2 #some answered, but not all mandatory
  end

  #a generated_section is available for a user to answer if it has no loop_item_type, or if its loop_item_type is not a filtering field
  # or if its loop_item is part of the user's loop_items.
  def available_for? user, loop_item
    return true if !self.loop_item_type.present? || !self.loop_item_type.is_filtering_field?
    obj = UserFilteringField.find_by_user_id_and_filtering_field_id(user.id, self.loop_item_type.filtering_field.id)
    if obj
      obj.field_value.downcase.strip == loop_item.item_name.downcase.strip
    else
      return false
    end
  end

  #remove loop_items from a set of items that are not available for a given user
  def remove_unavailable items, user
    aux = Array(items)
    items.each do |item|
      if !self.available_for? user, item
        aux.delete(item)
      end
    end
    aux
  end

  #check if a generated_section or any of its descendants has questions associated.
  def has_questions?
    return true if self.questions.any?
    self.children.each do  |s|
      return true if s.has_questions?
    end
    false
  end

  #get the next loop items that should be used to render the section
  # self: the section we are going to render.
  # loop_item: is the node of the tree where we currently are. We need to know what are the possible branches to descend to
  # loop_sources: hash that keeps record of the last item used for each loop_source in use
  def next_loop_items loop_item, loop_sources
    the_items = []
    #if loop_item exists and its descendants include the self's loop_item_type, find the loop_items that correspond to that loop item type
    if loop_item && loop_item.loop_item_type.descendants.include?(self.loop_item_type)
      the_items = loop_item.descendants.find_all_by_loop_item_type_id(self.loop_item_type_id)
    else
      #if it's not included check what was the last loop_item of that loop_source used, that info comes inside the loop_sources hash
      if loop_sources.present? && loop_sources[self.loop_source.id.to_s] && loop_sources[self.loop_source.id.to_s].loop_item_type.descendants.include?(self.loop_item_type)
        #having the last loop_item of the loop_item loop_source get it's descendants that are of self.loop_item_type
        the_items = loop_sources[self.loop_source.id.to_s].descendants.find_all_by_loop_item_type_id(self.loop_item_type_id)
      else #return the section loop item type's loop_items
        if self.loop_item_type
          the_items = self.loop_item_type.loop_items.order(:lft)
        end
      end
    end
  end

  #The purpose of this function is to run the maximum number of queries at the same time, so that rendering of the views isn't
  #interrupted  by db access
  #Get a section descendants' section_fields. And their questions' question_fields, and the answer type existing options
  # And the answer_types help text and the options text in "language".
  # The information is stored in the fields hash.
  # For sections and questions returns also the fields for the default language.
  # Because the section_field object has more than one field (title, description, etc) and so one of those can be empty
  # and it will be necessary to store and then use the section_field of the default language.
  def objects_fields_in language, fields
    #store the sections_field in language, but also the default language, for fail safe purposes
    fields[:sections_field] ||= {}
    #stores object if language is not the default language. nil otherwise || If language is the default one, the object will be in sections_field
    fields[:sections_field_default] ||= {}
    #store the questions_field in language, but also the default language, for fail safe purposes
    fields[:questions_field] ||= {}
    #stores object if language is not the default language. nil otherwise || If language is the default one, the object will be in questions_field
    fields[:questions_field_default] ||= {}
    fields[:answer_types_field] ||= {}
    fields[:multi_answer_option_field] ||= {}
    fields[:other_text_fields] ||= {}
    fields[:range_answer_option_field] ||= {}
    fields[:rank_answer_option_field] ||= {}
    fields[:matrix_answer_query_field] ||={}
    fields[:matrix_answer_option_field] ||={}
    fields[:matrix_answer_drop_option_field] ||= {}
    self.self_and_descendants.each do |s|
      fields[:sections_field][s.id.to_s] = s.section_fields.find_by_language(language)
      fields[:sections_field_default][s.id.to_s] = fields[:sections_field][s.id.to_s] && fields[:sections_field][s.id.to_s].is_default_language? ? nil : s.section_fields.find_by_is_default_language(true)
      s.questions.find(:all, :include => [:answer_type]).each do |q|
        fields[:questions_field][q.id.to_s] = q.question_fields.find_by_language(language)
        fields[:questions_field_default][q.id.to_s] = fields[:questions_field][q.id.to_s] && fields[:questions_field][q.id.to_s].is_default_language? ? nil : q.question_fields.find_by_is_default_language(true)
        answer_type_identifier = q.answer_type_id.to_s + "_" + q.answer_type_type
        fields[:answer_types_field][answer_type_identifier] =  (q.answer_type.present? && q.answer_type.help_text.present?) ? q.answer_type.value_in(:help_text, language) : fields[:answer_types_field][answer_type_identifier].present? ? fields[:answer_types_field][answer_type_identifier] : nil
        if  q.answer_type.is_a?(MultiAnswer) || q.answer_type.is_a?(RankAnswer) || q.answer_type.is_a?(RangeAnswer)
          atype = q.answer_type_type
          q.answer_type.send(atype.underscore.downcase+"_options").each do |option|
            field = option.send(option.class.to_s.underscore.downcase+"_fields").find_by_language(language)
            if field && field.option_text.present?
              fields[(option.class.to_s.underscore.downcase+"_field").to_sym][option.id.to_s] = field.option_text
            else
              fields[(option.class.to_s.underscore.downcase+"_field").to_sym][option.id.to_s] = option.send(option.class.to_s.underscore.downcase+"_fields").find_by_is_default_language(true).option_text
            end
          end
          #get the "other field" label in the questionnaire language necessary
          if q.answer_type.is_a?(MultiAnswer) && q.answer_type.other_required?
            other_field = q.answer_type.other_fields.present? ? (q.answer_type.other_fields.find_by_language(language) || q.answer_type.other_fields.find_by_is_default_language(true)) : "Other"
            fields[:other_text_fields][q.answer_type.id.to_s] = other_field.is_a?(OtherField) ?  other_field.other_text : other_field
          end
        elsif q.answer_type.is_a?(MatrixAnswer)
          q.answer_type.matrix_answer_queries.each do |maq|
            field = maq.matrix_answer_query_fields.find_by_language(language)
            fields[:matrix_answer_query_field][maq.id.to_s] = field.title.present? ? field.title : maq.matrix_answer_query_fields.find_by_is_default_language(true).title
          end
          q.answer_type.matrix_answer_options.each do |mao|
            field = mao.matrix_answer_option_fields.find_by_language(language)
            fields[:matrix_answer_option_field][mao.id.to_s] = field.title.present? ? field.title : mao.matrix_answer_option_fields.find_by_is_default_language(true).title
          end
          q.answer_type.matrix_answer_drop_options.each do |mado|
            field = mado.matrix_answer_drop_option_fields.find_by_language(language)
            fields[:matrix_answer_drop_option_field][mado.id.to_s] = field.option_text.present? ? field.option_text : mado.matrix_answer_drop_option_fields.find_by_is_default_language(true).option_text
          end
        end
      end
    end
  end

  def self.fill_lazy_load_details params
    details = {}
    details[:disabled] = params[:disabled] == "true" ? true : false
    details[:preloaded] = params[:preloaded].present? ? true : false
    details[:loop_item] = params[:loop_item_id] == "-1" ? nil : LoopItem.find(params[:loop_item_id])
    details[:section_visible] = params[:section_visible] == "true" ? true : false
    details[:loop_sources] = {}
    details[:old_multiplier] = params[:multiplier].to_i
    if params[:loop_sources].present?
      params[:loop_sources].each do |source_id, item_id|
        details[:loop_sources][source_id] = LoopItem.find(item_id.to_i)
      end
    end
    details[:loop_sources][details[:loop_item].loop_item_type.root.loop_source.id.to_s] = details[:loop_item] if details[:loop_item]
    if details[:preloaded]
      details[:looping_identifier] = params[:looping_identifier].present? ? params[:looping_identifier] : nil
    else
      details[:looping_identifier] = (params[:looping_identifier].present? ? "#{params[:looping_identifier]}#{LoopItem::LOOPING_ID_SEPARATOR}" : "")+details[:loop_item].id.to_s
    end
    details
  end

  #TODO: not finished. Needs to be further tested.
  def remove_submission_elements!
    self.children.each do |child|
      child.remove_submission_elements!
    end
    self.questions.each do |question|
      question.answers.each do |answer|
        answer.destroy
      end
    end
  end

  def tab_title lang=nil
    field = lang ? self.section_fields.find_by_language(lang) : nil
    the_title = field ? field.tab_title : self.section_fields.find_by_is_default_language(true).try(:tab_title)
    (the_title || nil)
  end

  def children_can_be_displayed_in_tab?
    return false if self.level >= ( self.questionnaire.display_in_tab_max_level || 3).to_i
    self.self_and_ancestors.each do |ancestor|
      if ancestor.loop_source.present?
        return false
      end
    end
    true
  end

  def loop_item_names
    result = {}
    self.loop_item_type.loop_item_names.each do |item_name|
      result[item_name.id.to_s] = item_name.item_name
    end
    result
  end

  # used in pivot table report
  def build_all_looping_identifiers
    if self.loop_item_type.present?
      loop_item_type = self.loop_item_type
      loop_item_types = [loop_item_type]
      while loop_item_type.parent.present?
        loop_item_type = loop_item_type.parent
        loop_item_types << loop_item_type
      end
      loop_item_ids_combinations =
        loop_item_types.map do |lit|
          lit.loop_items.pluck(:id)
        end.inject{ |memo, last| last.product(memo) }.map(&:flatten)
      loop_item_ids_combinations.map do |loop_item_ids_ary|
        loop_item_ids_ary.join(LoopItem::LOOPING_ID_SEPARATOR)
      end
    else
      []
    end
  end

  def any_answers_from? user, loop_sources_items, loop_item, looping_identifier=nil
    answers = Answer.where(question_id: self.questions.map(&:id), user_id: user.id)
    # Necessary because of what looks like a bug,
    # which is assigning either 0 or nil for empty looping_identifiers
    if looping_identifier.present?
      answers = answers.where(looping_identifier: looping_identifier)
    else
      answers = answers.where("looping_identifier = '0' OR looping_identifier IS NULL")
    end
    return true if !answers.select(&:filled_answer?).empty?
    self.children.each do |s|
      next if s.depends_on_option && !s.dependency_condition_met?(user, looping_identifier)
      if s.looping?
        items = s.next_loop_items loop_item, loop_sources_items
        items.each do |item|
          if s.available_for? user, item
            loop_sources_items[s.loop_source.id.to_s] = item
            new_looping_identifier = looping_identifier.present? ? "#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}#{item.id}" : item.id.to_s
            return true if s.any_answers_from? user, loop_sources_items, item, new_looping_identifier
          end
        end
      else
        return true if s.any_answers_from? user, loop_sources_items, loop_item, looping_identifier
      end
    end
    false
  end

  def delegations_from user
    self.delegation_sections.find(:all, :joins => {:delegation => :user_delegate}, :conditions => {:user_delegates => {:user_id => user.id}})
  end

  def is_delegated? user_delegate_id
    self.delegations.where(user_delegate_id: user_delegate_id).present?
  end

  private

  #after_save callback to handle question_extras_ids
  def update_section_extras
    unless section_extras_ids.nil?
      self.section_extras.each do |m|
        m.destroy unless section_extras_ids.include?(m.extra.to_s)
        section_extras_ids.delete(m.extra.to_s)
      end
      section_extras_ids.each do |g|
        self.section_extras.create(:extra_id => g) unless g.blank?
      end
      reload
      self.section_extras_ids = nil
    end
  end

  def coherence_of_type
    if !self.looping?  && (self.loop_item_type || self.loop_source)
      self.loop_item_type_id = nil
      self.loop_source_id = nil
    elsif self.looping? && (!self.loop_item_type || !self.loop_source)
      self.loop_item_type_id = nil
      self.loop_source_id = nil
      self.section_type = SectionType::REGULAR
    end
  end
end

# == Schema Information
#
# Table name: sections
#
#  id                      :integer          not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  last_edited             :datetime
#  section_type            :integer          not null
#  answer_type_id          :integer
#  answer_type_type        :string(255)
#  loop_source_id          :integer
#  loop_item_type_id       :integer
#  depends_on_option_id    :integer
#  depends_on_option_value :boolean          default(TRUE)
#  depends_on_question_id  :integer
#  is_hidden               :boolean          default(FALSE)
#  starts_collapsed        :boolean          default(FALSE)
#  display_in_tab          :boolean          default(FALSE)
#  original_id             :integer
#
