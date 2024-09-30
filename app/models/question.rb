class Question < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods
  include SectionsAndQuestionsShared

  attr_accessible :section_id, :answer_type_id, :answer_type_type,
    :question_fields_attributes, :is_mandatory, :answer_type,
    :loop_item_type_ids, :question_extras_ids, :other_text,
    :allow_attachments, :uidentifier
  #attr_protected :id, :created_at, :updated_at, :last_edited, :answer_type

  before_destroy :destroy_answer_type

  ###
  ###   Relationships
  ###
  #relation to the questionnaire through questionnaire_parts table.
  has_one :questionnaire_part, :as => :part
  belongs_to :section
  belongs_to :answer_type, :polymorphic => true
  has_many :question_loop_types, :dependent => :destroy
  accepts_nested_attributes_for :question_loop_types, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :loop_item_types, :through => :question_loop_types
  #submission side of the tool
  has_many :sections, foreign_key: :depends_on_question_id, dependent: :nullify
  has_many :question_fields, :dependent => :destroy
  accepts_nested_attributes_for :question_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :answers, dependent: :destroy
  has_many :question_extras, :dependent => :destroy
  has_many :extras, :through => :question_extras

  attr_accessor :loop_item_type_ids, :question_extras_ids
  after_save :update_loop_item_types, :update_question_extras
  ###
  ###   Validations
  ###
  validates_associated :question_fields

  ###
  ###   Methods
  ###

  def self.create_question_from params
    question = self.new(params[:part])
    question.answer_type = Question.create_question_answer_type params
    question
  end

  #create the question's answer_type or use the section answer type
  def self.create_question_answer_type params
    if params[:answer_type]
      answer_type = params[:part][:answer_type_type].classify.constantize.new(sorted_params(params))
      if answer_type.save
        answer_type
      end
    else
      Section.find(params[:part][:section_id]).answer_type
    end
  end

  def update_answer_type params
    if params[:part][:answer_type_type] == self.answer_type_type
      #if the answer type is the same, just update the answer_type attributes
      self.answer_type.update_attributes!(self.class.sorted_params(params))
    else
      if self.answers.present? #changing a question's answer_type will cause any existing answers to that question to be removed
        self.remove_submission_elements!
      end
      #if the previous answer_type doesn't have other questions or sections associated, destroy it
      if self.answer_type.questions.count == 1 && self.answer_type.sections.count == 0
        self.answer_type.class.find(self.answer_type_id).destroy
      end
      #create thew new answer type based on the params (if they exist. For questions of "same answer type" sections, it doesn't exist.
      if params[:part][:answer_type_type]
        self.answer_type = params[:part][:answer_type_type].classify.constantize.new(self.class.sorted_params(params))
        self.answer_type.save!
      end
    end
  end

  def short_title
    the_short = self.question_fields.find_by_is_default_language(true).short_title
    the_short ? the_short : "#Not Specified#"
  end

  # Function to save the answers of a question
  # Params:
  # params (Hash or String): the data that has been input for this question.id + identifier (if it exists) . params is an hash when the answer type is MultiAnswer and the selection type is multiple. Otherwise it will be a string.
  # answer (Answer): the answer object that will store the answer for this question+identifier . Is unique for [user.id, question.id, looping_identifier]
  # other_text (string): For Multi Answer questions an "other"  option might exist. the variable other_text holds its value
  # fields_to_clear (hash): hash with the form id of the other_text, if it is to be cleared (when the other option is not selected)
  # details_fields (hash): For multiAnswers options can have a "details field", the data that has been input in those fields comes in this variable. An hash :multi_option_id => :details_text
  def save_answers(params, answer, other_text, fields_to_clear, details_fields)
    saved_something = false
    if other_text
      #check if the "other" field has been selected.
      # If params is an hash we are dealing with a check-boxes answer type and the 'other' is selected if params["-1"].present?
      # If params is a String its either a radio button or a drop down or a select box. So if its a radio button params should be equal to "-1" for 'other' to be selected. For drop down or select box other_text just needs to be presented (not blank)
      if ( (params.is_a?(Hash) && !params["-1"].present? ) || (params.is_a?(String) && self.answer_type.display_type != 1 && params != "-1" )) &&  !other_text.blank?
        answer.other_text = ""
        answer.save!
        saved_something = true
        fields_to_clear << "answer_#{answer.question_id.to_s + (answer.looping_identifier.present? ? "_#{answer.looping_identifier}" : "")}_other"
      else
        if answer.other_text != other_text
          answer.other_text = other_text
          answer.save!
          saved_something = true
        end
      end
    end
    if self.answer_type.is_a?(MultiAnswer)
      self.answer_type.save_answers(params, answer, details_fields, fields_to_clear) || saved_something
    else
      self.answer_type.save_answers(params, answer) || saved_something
    end
  end

  #Verifies if the params for a specific question contain any answer.
  #This check depends on the type of answer, indicated by the class of the params related to that answer.
  def self.answer_present? entered_answer
    if entered_answer.is_a?(String) || entered_answer.is_a?(Array)
      entered_answer.present?
    elsif entered_answer.is_a?(Hash)
      entered_answer.values.to_s.present?
    else
      false
    end
  end

  def answered_status(user, looping_identifier=nil)# returns false => answers missing, true => at least one answer filled
    Array(self.answers.find_by_user_id_and_looping_identifier(user.id, looping_identifier)).each do |answer|
      if answer.other_text.present?
        return true
      end
      if !answer.answer_parts.empty?
        answer.answer_parts.each do |ap|
          #Is answerd if it's a TextAnswer or NumericAnswer and it has a answer_text
          #Or if it's not of that type and the field (MultiAnswerOption, RangeAnswerOption, RankAnswerOption) exists
          #Or if it has answer_part_matrix_options present
          if (ap.answer_text && ap.answer_text != "") ||
              (!["TextAnswerField", "NumericAnswer"].include?(ap.field_type_type) && ap.field_type.present?) ||
              ( ap.answer_part_matrix_options.any? )
            return true
          end
        end
      end
    end
    # deselected or unselected single option multi answers
    if self.answer_type_type == 'MultiAnswer' && self.answer_type &&
      self.answer_type.multi_answer_options.count == 1
      return true
    end
    false
  end

  def remove_submission_elements!
    self.answers.each do |answer|
      answer.destroy
    end
  end

  def self.get_answer answers, q_id, looping_identifier=nil
    return nil if answers.empty?
    answers.each do |answer|
      return answer if ( answer.question_id == q_id && ( !looping_identifier || (answer.looping_identifier == looping_identifier.to_s)) )
    end
    nil
  end

  #
  # @return [Boolean] True if it's nested under a dependent section, false otherwise
  # @return [Section, nil] Returns the dependent section this question is nested under, returns nil if the section is not nested under a dependent section
  def nested_under_dependent_section?
    return [true, self.section] if self.section.depends_on_question.present?
    self.section.ancestors.each do |ancestor|
      return [true, ancestor] if ancestor.depends_on_question.present?
    end
    false
  end

  def to_csv csv, submitters_ids, loop_sources=nil, loop_item=nil, looping_identifier=nil
    answers = {}
    submitters_ids.each_with_index do |val, i|
      if looping_identifier
        answers[val.to_s] = self.answers.find(:first, :conditions => {:user_id => val, :looping_identifier => looping_identifier})
      else
        answers[val.to_s] = self.answers.find_by_user_id(val)
      end
    end
    if loop_item
      s_title = "." + "--"*self.section.level + OrtSanitize.white_space_cleanse(self.section.section_fields.find_by_is_default_language(true).loop_title(nil, loop_item))
      q_title = OrtSanitize.white_space_cleanse(self.question_fields.find_by_is_default_language(true).loop_title(loop_sources, loop_item))
    else
      s_title = "." + "--"*self.section.level + OrtSanitize.white_space_cleanse(self.section.title)
      q_title = OrtSanitize.white_space_cleanse(self.title)
    end
    if self.section.depends_on_option
      s_title += " - This section depends on the option #{self.section.depends_on_option.multi_answer_option_fields.find_by_is_default_language(true).option_text}
                       being #{self.section.depends_on_option_value? ? "selected" : "not selected"}, for question #{self.section.depends_on_question.title} of #{self.section.depends_on_question.section.title}"
    end
    q_identifier = self.uidentifier
    if [MultiAnswer, NumericAnswer, RangeAnswer, TextAnswer].include?(self.answer_type.class)
      csv_answers = CsvMethods.answers_to_csv(s_title, q_title, q_identifier, submitters_ids, answers)
      csv_answers[0].is_a?(Array) ? csv << csv_answers[0] && csv << csv_answers[1] : csv << csv_answers
    else
      self.answer_type.class.to_csv(csv, self.answer_type, s_title, q_title, q_identifier, submitters_ids, answers)
    end
  end

  def can_edit_text_answer? answer, user_delegate
    delegate = user_delegate.present? ? user_delegate.delegate : nil
    return true if delegate && questionnaire.can_act_as_a_super_delegate?(delegate)
    !((self.answer_type_type == 'TextAnswer' && user_delegate.present?) || (answer && answer.question_answered))
  end

  ###
  ###   Callbacks
  ###

  private

  #after_save callback to handle loop_item_type_ids
  def update_loop_item_types
    unless loop_item_type_ids.nil?
      self.question_loop_types.each do |m|
        m.destroy unless loop_item_type_ids.include?(m.loop_item_type.to_s)
        loop_item_type_ids.delete(m.loop_item_type.to_s)
      end
      loop_item_type_ids.each do |g|
        self.question_loop_types.create(:loop_item_type_id => g) unless g.blank?
      end
      reload
      self.loop_item_type_ids = nil
    end
  end

  #after_save callback to handle question_extras_ids
  def update_question_extras
    unless question_extras_ids.nil?
      self.question_extras.each do |m|
        m.destroy unless question_extras_ids.include?(m.extra.to_s)
        question_extras_ids.delete(m.extra.to_s)
      end
      question_extras_ids.each do |g|
        self.question_extras.create(:extra_id => g) unless g.blank?
      end
      reload
      self.question_extras_ids = nil
    end
  end

  def self.sorted_params(params)
    attrs = params[:answer_type]

    if attrs[:matrix_answer_queries_attributes].present?
      attrs[:matrix_answer_queries_attributes] =
        attrs[:matrix_answer_queries_attributes].sort_by { |k,_| k }.to_h
    end

    if attrs[:matrix_answer_options_attributes].present?
      attrs[:matrix_answer_options_attributes] =
        attrs[:matrix_answer_options_attributes].sort_by { |k,_| k }.to_h
    end

    attrs
  end
end

# == Schema Information
#
# Table name: questions
#
#  id                :integer          not null, primary key
#  uidentifier       :string(255)
#  last_edited       :datetime
#  section_id        :integer          not null
#  answer_type_id    :integer
#  answer_type_type  :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_mandatory      :boolean          default(FALSE)
#  allow_attachments :boolean          default(TRUE)
#  original_id       :integer
#
