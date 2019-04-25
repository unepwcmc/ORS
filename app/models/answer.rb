class Answer < ActiveRecord::Base
  #attr_accessible :user_id, :question_id, :questionnaire_id, :deleted
  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  #belongs_to :generated_question
  belongs_to :question
  belongs_to :user
  belongs_to :last_editor, :class_name => 'User'
  belongs_to :questionnaire
  belongs_to :loop_item
  has_many :answer_parts, :dependent => :destroy
  has_many :documents, :dependent => :destroy
  accepts_nested_attributes_for :documents, :reject_if => lambda { |a| a[:doc].blank? && a[:description].blank? }, :allow_destroy => true
  has_many :answer_links, :dependent => :destroy
  accepts_nested_attributes_for :answer_links, :reject_if => lambda { |a| a[:url].blank? && a[:title].blank? && a[:description].blank?  }, :allow_destroy => true
  has_many :delegate_text_answers, dependent: :destroy

  ###
  ###  Validations
  ###
  validates_uniqueness_of :questionnaire_id, :scope => [:question_id, :user_id, :looping_identifier]

  # How are the answers being stored:
  # Answer has (questionnaire_id, user_id, question_id, loop_item_id)
  # loop_item_id: exists if the answer is from a question that is part of a looping section.
  # This loop_item_id makes the answer unique for that branch of looping.
  # Each answer will have 1..* parts (for instance multiple text-fields, multiple checkboxes, multiple list items.
  # In the submission pane the user can save each sections questions.
  # For each question on that section it will be called the save_answer method (vide section.rb, question.rb, multi_answer.rb, text_answer.rb)
  # This method will check if there is an existing answer_part for the answer of the specific question. If it does exist it updates
  # accordingly. If it doesn't it creates a new answer_part. Each AnswerPart has a link to a MultiAnswerOption or to a TextAnswerField,
  # that way it requires less information to be stored in it and makes it easier in the views side. Allowing to populate the form with
  # the correct values if they exist.
  #

  ###
  ###   Methods
  ###

  def self.validate_the_urls params
    params[:answer_links_attributes].delete("new_answer_links")
    params[:answer_links_attributes].each do |id, values|
      begin
        aux = URI.parse(values["url"])
        if !aux.scheme && values[:url].present?
          params[:answer_links_attributes][id][:url] = "http://" + params[:answer_links_attributes][id][:url]
        end
      rescue URI::InvalidURIError
        params[:answer_links_attributes][id][:_destroy] = 1
      end
    end
  end

  #for text_answer type  answers
  def get_text_answer_field_if_it_exists text_answer_field, translator_visible
    result = {}
    ap = self.answer_parts.find_by_field_type_id(text_answer_field.id)
    if ap
      result[:answer_text] = ap.answer_text || ""
      result[:original_language] = ap.original_language.present? ? ap.original_language :  nil
      result[:answer_text_in_english] = ap.answer_text_in_english || "" if translator_visible
      result
    else
      nil
    end
  end

  def matrix_cells_answers selection
    self.answer_parts.each do |answer_part|
      selection[answer_part.field_type_id.to_s] ||= {}
      answer_part.answer_part_matrix_options.each do |apmo|
        selection[answer_part.field_type_id.to_s][apmo.matrix_answer_option_id.to_s] ||= []
        if apmo.answer_text.present?
          selection[answer_part.field_type_id.to_s][apmo.matrix_answer_option_id.to_s] = apmo.answer_text
        elsif apmo.matrix_answer_drop_option_id
          selection[answer_part.field_type_id.to_s][apmo.matrix_answer_option_id.to_s] << apmo.matrix_answer_drop_option_id
        else
          selection[answer_part.field_type_id.to_s][apmo.matrix_answer_option_id.to_s] ||= []
        end
      end
    end
  end

  def self.find_or_create_new_answer(question, user, questionnaire, from_dependent_section, looping_identifier=nil)
    if looping_identifier.present?
      answer = Answer.find_or_create_by_question_id_and_user_id_and_questionnaire_id_and_looping_identifier(question.id, user.id, questionnaire.id, looping_identifier)
    else
      # TODO Can add order: 'id ASC' to Answer.find... to always fetch the same answer
      # if there are many. Won't work with Answer.find_or_create_by but only with Answer.find_by.
      answer = Answer.find_or_create_by_question_id_and_user_id_and_questionnaire_id(question.id, user.id, questionnaire.id)
    end
    if answer.from_dependent_section != from_dependent_section
      answer.from_dependent_section = from_dependent_section
      answer.save
    end
    answer
  end

  # Method to save the input of the user in the questionnaire as answers.
  #
  # @param [Questionnaire] questionnaire Questionnaire being replied by the user
  # @param [User] user User whose answers are being saved
  # @param [User] editor User who is saving the answers
  # @param [Hash] user_answers Hash with the answers of the user. The key is a string that contains the question_id, the looping_identifier (or zero), and some more information depending on the type of answer. The value is the user actual answer.
  # @param [Hash] dependent_sections_state Hash with the state of the dependent sections of the questionnaire. ( {section_id_loop_item => hidden or not (1- hidden; 0- visible)}
  def self.save_answers questionnaire, user, editor, user_answers, dependent_sections_state
    answers = []
    parts_saved = []
    result = false
    auth_error = false
    user_answers.each do |identifiers, val|
      question_id, looping_identifier, field_id, extra_val = identifiers.split("_")
      looping_identifier = nil if !looping_identifier.present? || looping_identifier == "0"
      question = Question.find(question_id)
      if ((user.id != editor.id && !editor.role_can_edit_respondents_answers?) && question.answer_type_type == "TextAnswer")
        auth_error = true
        next
      end
      from_dependent_section, dependent_section = question.nested_under_dependent_section?
      #If the question is nested under a dependent section, one needs to check if there were changes with the availability of a dependent section. That is defined inside the 'dependent_sections_state' hash.
      #If the dependent_section is hidden this method adds it to an array of dependent_sections_to_hide that will be used to set those sections submission state to be marked as 'dont_care' (for the overall state of the section tree)
      #The dependent_section answer parts will be destroyed
      if from_dependent_section && dependent_section && dependent_sections_state && dependent_sections_state["#{dependent_section}_#{looping_identifier||"0"}"] == "1"
        if looping_identifier
          answer = Answer.find_by_question_id_and_user_id_and_questionnair_id_and_looping_identifier_and_from_dependent_section(question.id, user.id, questionnaire.id, looping_identifier, from_dependent_section)
        else
          answer = Answer.find_by_question_id_and_user_id_and_questionnair_id_and_from_dependent_section(question.id, user.id, questionnaire.id, from_dependent_section)
        end
        if answer && !answer.question_answered
          if question.answer_type_type == "MatrixAnswer"
            to_remove = answer.answer_parts.map{ |ap| ap.answer_part_matrix_options }.flatten
          else
            to_remove = answer.answer_parts
          end
          if !to_remove.empty?
            to_remove.map{ |a| a.delete }
            result = true
          end
        end
        next #move to the next answer
      end
      answer = self.find_or_create_new_answer(question, user, questionnaire, from_dependent_section, looping_identifier)
      answers << answer if !answers.include?(answer)
      #Depending on the question's answer_type a different method is called.
      #The methods return saved answer_parts (or answer_parts components) and a set of objects to be removed
      #The 'saved' objects are saved inside the methods because for some answer_type's more than one component for each answer might be submited at once (namely the multi_answer's details field)
      #and that field wasn't saved at first because the corresponding answer_part was only saved in the end of this method. This way that won't happen as answer_parts are immediately saved.
      #They were being saved in group, as the deleted objects are deleted in group, to avoid many changes in context from ruby to database calls. Might be worth revising this if performance is not
      #good enough.
      unless answer.question_answered
        case question.answer_type_type
          when "TextAnswer"
            saved, int_result = TextAnswer.save_answer(val, answer, editor.id, field_id, extra_val)
          when "NumericAnswer"
            saved, int_result = NumericAnswer.save_answer(val, answer, editor.id, field_id)
          when "MultiAnswer"
            saved, int_result = MultiAnswer.save_answer(val, answer, editor.id, field_id, extra_val)
          when "RankAnswer"
            saved, int_result = RankAnswer.save_answer(val, answer, editor.id, field_id)
          when "RangeAnswer"
            saved, int_result = RangeAnswer.save_answer(val, answer, editor.id)
          when "MatrixAnswer"
            saved, int_result = MatrixAnswer.save_answer(val, answer, editor.id, field_id, extra_val)
        end
      end
      result = int_result || result
      if saved.is_a?(Array)
        parts_saved += saved
      elsif saved.present?
        parts_saved << saved
      end
    end
    if result
      Section.dependent_availability_changes(dependent_sections_state, user) if dependent_sections_state
      answers.map{ |a| [a.looping_identifier, a.question.section] }.uniq.reject{ |a,b| b.root? }.each do |looping_identifier, section|
        section.update_submission_state!(user, looping_identifier)
      end
    end
    [ result, parts_saved.map{ |ap| if ap.is_a?(AnswerPart) then ap.answer else nil end }.uniq.reject{ |a| a.nil? }.map{ |a| a.question_id.to_s + (a.looping_identifier.present? ? "_#{a.looping_identifier}" : "") }, [], auth_error]
  end

  # When a user removes an answer the answer record is not removed, but still should be considered as non existing
  # This method checks if an answer has any component that will make it be considered as filled
  # NOTE: Maybe removing an answer object when it reaches this state might be a better option, than having this check.
  def filled_answer?
    self.answer_parts.any? || self.other_text.present? || self.documents.any? || self.answer_links.any?
  end

  def old_answer?
    self.updated_at < self.question.created_at
  end

  def self.empty_text_answers_to_csv
    where_statement =
      """
        questions.answer_type_type = 'TextAnswer' AND
        delegate_text_answers.answer_text IS NOT NULL
        AND answers.id NOT IN ( SELECT answer_id FROM answer_parts)
      """
    empty_answers = Answer.includes(:questionnaire, :question, :user, :delegate_text_answers)
                          .where(where_statement)
    headers =  ["Questionnaire", "Question", "Email", "First name", "Last name"]

    CSV.generate do |csv|
      csv << headers
      empty_answers.each do |answer|
        questionnaire = answer.questionnaire.title
        question = answer.question.title
        user = answer.user
        email = user.email
        first_name = user.first_name
        last_name = user.last_name

        csv << [questionnaire, question, email, first_name, last_name]
      end
    end
  end

end

# == Schema Information
#
# Table name: answers
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  questionnaire_id       :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  other_text             :text
#  question_id            :integer          not null
#  looping_identifier     :string(255)
#  from_dependent_section :boolean          default(FALSE)
#  last_editor_id         :integer
#  loop_item_id           :integer
#  original_id            :integer
#  question_answered      :boolean          default(FALSE)
#
