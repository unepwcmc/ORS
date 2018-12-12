class Questionnaire < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods
  extend EnumerateIt
  has_enumeration_for :status, :with => QuestionnaireStatus, :create_helpers => true

  #attr_accessible :questionnaire_date, :administrator_remarks, :last_editor_id, :user_id, :questionnaire_fields_attributes, :header, :source_questionnaire
  attr_protected :id, :created_at, :updated_at

  ###
  ###   Paperclip
  ###
  has_attached_file :header,
    :styles => {:original => "940x90>", :thumb => "237x22>"},
    :default_url => "#{ActionController::Base.relative_url_root}/assets/headers/default/default_:style_header.png"
  validates_attachment_size :header,
    :less_than => 5.megabytes
  validates_attachment_content_type :header,
    :content_type => ["image/jpeg", "image/pjpeg","image/ppng", "image/png", "image/JPEG", "image/jpg", "image/JPG", "image/gif", "image/GIF", "image/PNG"]
  ###
  ###   Relationships
  ###
  belongs_to :user #the author of the questionnaire
  belongs_to :last_editor, :class_name => "User"
  has_many :submitters, :through => :authorized_submitters, :source => :user, :conditions => {:authorized_submitters => {:status => [SubmissionStatus::NOT_STARTED, SubmissionStatus::UNDERWAY, SubmissionStatus::SUBMITTED]}}
  has_many :authorized_submitters, :dependent => :destroy
  has_many :questionnaire_parts, :dependent => :destroy
  has_many :loop_sources, :include => :loop_item_type, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :documents, :through => :answers #documents from the users answers
  has_many :answer_links, :through => :answers #links from the users answes
  has_many :questionnaire_fields, :dependent => :destroy
  accepts_nested_attributes_for :questionnaire_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  belongs_to :source_questionnaire, :foreign_key => :original_id, :class_name => "Questionnaire"
  has_many :copies, :foreign_key => :original_id, :class_name => "Questionnaire"
  has_many :filtering_fields, :dependent => :destroy
  has_many :delegations, :dependent => :destroy
  has_many :user_delegates, :source => :user_delegate, :through => :delegations, :foreign_key => :delegate_id, :dependent => :destroy
  has_one :csv_file, :dependent => :destroy, :as => :entity
  has_many :pdf_files, :dependent => :destroy
  has_many :deadlines, :dependent => :destroy

  ###
  ###   Named Scopes
  ###
  scope :last_created, lambda { |num| {:limit => num, :order => 'created_at DESC', :include => :user} }
  scope :last_edited, lambda { |num| {:limit => num, :order => 'updated_at DESC', :include => :user} }
  scope :last_activated, lambda { |num| {:limit => num, :order => 'activated_at DESC', :conditions => ['status = 1'], :include => :user} }
  scope :closed_questionnaires, {:order => "created_at DESC", :conditions => ['status = 2'] , :include => :user}
  scope :authorized_questionnaires, lambda { |user| {:joins => :authorized_submitters, :conditions => ['authorized_submitters.user_id = ?', user.id], :include => :questionnaire_fields} }

  ###
  ###   Validations
  ###
  validates_presence_of :questionnaire_date #, :administrator_remarks
  validates_associated :questionnaire_fields

  ###
  ###   Methods
  ###

  def propagate_languages_changes old_languages, old_default_language
    questionnaire_languages = self.questionnaire_fields.reject{ |a| a.marked_for_destruction? }.map{ |a| a.language }
    new_default = self.questionnaire_fields.find_by_is_default_language(true).language
    langs_to_remove = old_languages - questionnaire_languages
    langs_to_add = questionnaire_languages - old_languages
    return if langs_to_remove.empty? && langs_to_add.empty? && new_default == old_default_language
    self.questionnaire_parts.each do |qpart|
      qpart.propagate_languages_changes(langs_to_remove, langs_to_add, (new_default == old_default_language ? nil : new_default))
    end
    self.loop_sources.each do |source|
      source.loop_item_names.each do |litem_name|
        litem_name.propagate_languages_changes(langs_to_remove, langs_to_add, (new_default == old_default_language ? nil : new_default))
        litem_name.item_extras.each do |item_extra|
          item_extra.propagate_languages_changes(langs_to_remove, langs_to_add, (new_default == old_default_language ? nil : new_default))
        end
      end
    end
  end

  def questionnaire_structure (params) # to display the questionnaire in the dynatree
    @obj = []
    self.questionnaire_parts.sort{ |a,b| a.lft <=> b.lft }.each do |qpart|
      children = qpart.children
      the_title = Sanitize.clean(qpart.display_title).strip.gsub("\n\n", "")
      @obj += [ {
        :title => the_title[0,25] + (the_title.size > 25 ? "..." : ""),
        :tooltip => the_title,
        :isFolder => qpart.part.is_a?(Section),
        :key => qpart.part.is_a?(Section) ? qpart.part_id.to_s : "q"+qpart.part_id.to_s,
        :expand => false,
        :activate => ( params[:activate] && params[:activate].to_i == qpart.part_id ) ? true : false,
        :children => QuestionnairePart.add_children_info(children, params)
      } ]
    end
    @obj
  end

  def available_languages
    self.questionnaire_fields.map{ |qf| qf.language }
  end

  #destroy sections, questions && answer_types of a questionnaire
  #TODO: destroy answers?
  def destroy_all_questionnaire_elements!
    #    puts "###########System Totals##########"
    #    puts "Total sections of the System: #{Section.count}"
    #    puts "Total questions of the System: #{Question.count}"
    #    puts "Total loop sources of the System: #{LoopSource.count}"
    #    puts "Total loop item names of the System: #{LoopItemName.count}"
    #    puts "Total loop item of the System: #{LoopItem.count}"
    #    puts "Total loop item type of the System: #{LoopItemType.count}"
    #    puts "Total multi answers of the System: #{MultiAnswer.count}"
    #    puts "Total multi answer options of the System: #{MultiAnswerOption.count}"
    #    puts "Total text answers of the System: #{TextAnswer.count}"
    #    puts "Total numeric answers of the System: #{NumericAnswer.count}"
    #    puts "Total questionnaire parts of the System: #{QuestionnairePart.count}"
    #    puts "###########Questionnaire Totals#############"
    #    counting_things = {}
    #    self.count_questionnaire_elements(counting_things)
    #    puts "Total sections of the Questionnaire: #{counting_things[:sections]}"
    #    puts "Total questions of the Questionnaire: #{counting_things[:questions]}"
    #    puts "Total loop sources of the Questionnaire: #{counting_things[:loop_sources]}"
    #    puts "Total loop item names of the Questionnaire: #{counting_things[:loop_item_names]}"
    #    puts "Total loop item of the Questionnaire: #{counting_things[:loop_items]}"
    #    puts "Total loop item type of the Questionnaire: #{counting_things[:loop_item_types]}"
    #    puts "Total multi answers of the Questionnaire: #{counting_things[:multi_answer]}"
    #    puts "Total multi answer options of the Questionnaire: #{counting_things[:multi_answer_options]}"
    #    puts "Total text answers of the Questionnaire: #{ counting_things[:text_answer]}"
    #    puts "Total numeric answers of the Questionnaire: #{ counting_things[:numeric_answer]}"
    #    puts "Total questionnaire parts of the Questionnaire: #{counting_things[:questionnaire_parts]}"
    self.loop_sources.each do |loop_source|
      loop_source.delete_smoothly
    end
    self.questionnaire_parts.each do |qpart|
      qpart.destroy_branch
    end
    #    puts "###########System Totals - After deleting the stuff ##########"
    #    puts "Total sections of the System: #{Section.count}"
    #    puts "Total questions of the System: #{Question.count}"
    #    puts "Total loop sources of the System: #{LoopSource.count}"
    #    puts "Total loop item names of the System: #{LoopItemName.count}"
    #    puts "Total loop item of the System: #{LoopItem.count}"
    #    puts "Total loop item type of the System: #{LoopItemType.count}"
    #    puts "Total multi answers of the System: #{MultiAnswer.count}"
    #    puts "Total multi answer options of the System: #{MultiAnswerOption.count}"
    #    puts "Total text answers of the System: #{TextAnswer.count}"
    #    puts "Total numeric answers of the System: #{NumericAnswer.count}"
    #    puts "Total questionnaire parts of the System: #{QuestionnairePart.count}"
  end

  #build questionnaire_field objects for the languages missing from the 6 existing languages
  def build_questionnaire_fields!
    languages = ['ar', 'zh', 'en', 'es', 'fr', 'ru'] - self.questionnaire_fields.map{ |a| a.language }#&:language
    languages.each do |lang|
      self.questionnaire_fields.build(:language => lang)
    end
    self.questionnaire_fields.sort!{ |a,b| a.language <=> b.language }
  end

  #Method to facilitate the printing of the Questionnaire Title
  #by printing the title in the default language
  def title lang=nil
    field = lang ? self.questionnaire_fields.find_by_language(lang) : nil
    the_title = field ? field.title : self.questionnaire_fields.find_by_is_default_language(true).title
    the_title ? the_title : "#Not Specified#"
  end

  def email lang=nil
    field = lang ? self.questionnaire_fields.find_by_language(lang) : nil
    field ? field.email : self.questionnaire_fields.find_by_is_default_language(true).email
  end

  def email_subject lang=nil
    field = lang ? self.questionnaire_fields.find_by_language(lang) : nil
    field ? field.email_subject : self.questionnaire_fields.find_by_is_default_language(true).email_subject
  end

  def email_footer lang=nil
    field = lang ? self.questionnaire_fields.find_by_language(lang) : nil
    field ? field.email_footer : self.questionnaire_fields.find_by_is_default_language(true).email_footer
  end

  def submit_info_tip lang=nil
    field = lang ? self.questionnaire_fields.find_by_language(lang) : nil
    field ? field.submit_info_tip : self.questionnaire_fields.find_by_is_default_language(true).submit_info_tip
  end

  def language
    self.questionnaire_fields.find_by_is_default_language(true).language
  end

  def introductory_remarks
    self.questionnaire_fields.find_by_is_default_language(true).introductory_remarks
  end

  #calculate the percentage of completion of a questionnaire by a specific user
  def percentage_of_completion_for user
    authorization = AuthorizedSubmitter.find_by_questionnaire_id_and_user_id(self.id, user.id)
    return 0.00 if authorization.answered_questions == 0 || authorization.total_questions == 0
    ( "%.2f" % ((authorization.answered_questions.to_f / authorization.total_questions.to_f) * 100) )
  end

  def count_questions_available_for user
    info_holder = {}
    info_holder[:available_questions] = 0
    self.sections.each do |section|
      if !section.depends_on_question.present?
        section.count_self_and_descendants_questions(user, info_holder)
      end
    end
    info_holder[:available_questions]
  end

  #check if a questionnaire has at least one question
  def has_questions?
    self.sections.each do |section|
      section.self_and_descendants do |s|
        if s.questions.present?
          return true
        end
      end
    end
    false
  end

  #get the number of questions from a questionnaire
  def questions_count
    from_sql = ActiveRecord::Base.send(:sanitize_sql_array, ["questionnaire_questions(?)", self.id])
    Questionnaire.from(from_sql).count
  end

  def sections_count
    from_sql = ActiveRecord::Base.send(:sanitize_sql_array, ["questionnaire_sections(?)", self.id])
    Questionnaire.from(from_sql).count
  end

  def close!
    return false if !self.active?
    self.status = QuestionnaireStatus::CLOSED
    self.save!
  end

  def open!
    return false if !self.closed?
    self.status = QuestionnaireStatus::INACTIVE
    self.save!
  end

  def activate!
    return false if !self.inactive?
    self.status = QuestionnaireStatus::ACTIVE
    self.activated_at= Time.now
    self.save!
  end

  def deactivate!
    self.status = QuestionnaireStatus::INACTIVE
    self.save!
  end

  def is_closed?
    self.status == 2
  end

  #Returns an array with all the root sections, obtained through questionnaire parts.
  def sections
    #self.questionnaire_parts.sort.map{|a| a.part}.reject{|a| !a.is_a?(Section)}
    q_ids = self.questionnaire_parts.find(:all, :conditions => {:part_type => "Section"})
    Section.find(q_ids.map(&:part_id), :joins => :questionnaire_part, :order => "questionnaire_parts.lft ASC", :include => [:questionnaire_part])
  end

  def sections_to_display_in_tab
    Section.select('*').from(
      ActiveRecord::Base.send(:sanitize_sql_array,
        [
          "(
            SELECT sections.*
            FROM questionnaire_parts_with_descendents(:questionnaire_id)
            JOIN sections ON part_id = sections.id AND part_type = 'Section'
            WHERE questionnaire_id IS NOT NULL OR display_in_tab
            ORDER BY lft
          ) sections",
          questionnaire_id: self.id
        ]
      )
    ).preload(:questionnaire_part, :section_fields)
  end

  def questionnaire_structure_for_js_tree (params) # to display the questionnaire in the dynatree
    tree_children = []
    self.questionnaire_parts.sort{ |a,b| a.lft <=> b.lft }.each do |qpart|
      children = qpart.children
      the_title = Sanitize.clean(qpart.display_title).strip.gsub("\n\n", "")
      tree_children += [ {
        :data => {
        :title => the_title,
        :icon => qpart.part.is_a?(Section) ? "folder" : "/assets/dynatree/ltDoc.gif"
      },
        #:tooltip => the_title,
        #:isFolder => qpart.part.is_a?(Section),
        #:key => qpart.part.is_a?(Section) ? qpart.part_id.to_s : "q"+qpart.part_id.to_s,
        :attr => {:id => qpart.id.to_s, :movable => "true", :targetable => "true", :is_question => "false", :looping_branch => qpart.part.loop_source.present?,
          :display_in_tab => "true"},
          :state => children.present? ? "closed" : "leaf",
          #:activate => ( params[:activate] && params[:activate].to_i == qpart.part_id ) ? true : false,
          :children => QuestionnairePart.add_children_info_to_jstree(children, params, !qpart.part.loop_source_id.present?)
      } ]
    end
    obj = [
      {
      :data => {
      :title => self.title,
      :icon => "folder"
    },
      :attr => {:id => "root", :targetable => "true"},
      :state => "open",
      :children => tree_children
    }
    ]
    obj
  end

  def move_the_questionnaire_part params
    part_to_move = QuestionnairePart.find(params[:node_id])
    if params[:new_parent] == "root"
      if self.questionnaire_parts.size != params[:position_index].to_i
        gonna_be_right_sibling = self.questionnaire_parts.sort[params[:position_index].to_i]
        part_to_move.move_to_left_of gonna_be_right_sibling
      else
        part_to_move.move_to_right_of self.questionnaire_parts.sort.last
      end
    else
      parent_destination = QuestionnairePart.find(params[:new_parent])
      if parent_destination.children.size != params[:position_index].to_i
        gonna_be_right_sibling = parent_destination.children[params[:position_index].to_i]
        part_to_move.move_to_left_of gonna_be_right_sibling
      else
        if parent_destination.children.present?
          part_to_move.move_to_right_of parent_destination.children.last
        else
          part_to_move.move_to_child_of parent_destination
        end
      end
      if part_to_move.part.is_a?(Question) && parent_destination.part.is_a?(Section)
        part_to_move.part.section_id = parent_destination.part.id
      end
    end
    if part_to_move.root?
      part_to_move.questionnaire = self
    else
      part_to_move.questionnaire = nil
    end
    part_to_move.save
  end

  def can_act_as_a_super_delegate?(user)
    enable_super_delegates && user.role?(:super_delegate)
  end
end

# == Schema Information
#
# Table name: questionnaires
#
#  id                       :integer          not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  last_edited              :datetime
#  user_id                  :integer          not null
#  last_editor_id           :integer
#  activated_at             :datetime
#  administrator_remarks    :text
#  questionnaire_date       :date
#  header_file_name         :string(255)
#  header_content_type      :string(255)
#  header_file_size         :integer
#  header_updated_at        :datetime
#  status                   :integer          default(0)
#  display_in_tab_max_level :string(255)      default("3")
#  delegation_enabled       :boolean          default(TRUE)
#  help_pages               :string(255)
#  translator_visible       :boolean          default(FALSE)
#  private_documents        :boolean          default(TRUE)
#  original_id              :integer
#
