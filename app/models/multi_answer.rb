class MultiAnswer < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods
  include AnswerTypeMethods

  ###
  ###   Relationships
  ###
  has_many :questions, :as => :answer_type
  has_many  :sections, :as => :answer_type
  has_many :multi_answer_options, :dependent => :destroy, :include => :multi_answer_option_fields
  #=> submission side of the tool
  has_many :answer_type_fields, :as => :answer_type, :dependent => :destroy
  has_many :other_fields, :dependent => :destroy
  accepts_nested_attributes_for :other_fields,:answer_type_fields, :multi_answer_options, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  ###
  ###   Validations
  ###
  validates_associated :answer_type_fields

  attr_accessible :answer_type_fields_attributes, :display_type,
    :single, :other_required, :other_fields_attributes,
    :multi_answer_options_attributes

  ###
  ###   Methods
  ###

  def has_options_with_dependents?
    self.multi_answer_options.each do |mao|
      if mao.sections.present?
        return true #returns true when the multi answer option has dependent sections
      end
    end
    false
  end

  #Saving Multi Answer: input format of 'identifiers' => 'val'
  ## Other Field: "question_id, loop_item_id, 'other'(field_id)" => "val"(val)
  ## Details field: "question_id, loop_item_id, option_id(field_id), 'details'(extra_val) => "text"(val)
  ## Multiple Select: "question_id, loop_item_id" => [option1, option2](val)
  ## Check-boxes: "question_id, loop_item_id, option_id(field_id)" => option_id || "" (val)
  ## Radio-buttons: "question_id, loop_item_id, option_id(feld_id)" => option_id(val)
  ## Select: "question_id, loop_item_id" => option_id || "" (val)
  def self.save_answer val, answer, editor_id, field_id, extra_val
    saved = []
    to_remove = []
    result = false
    question = answer.question
    if 'other' == field_id
      answer.other_text = val
      if answer.changed?
        answer.save
        result = true
      end
    elsif 'details' == extra_val
      ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "MultiAnswerOption") || AnswerPart.new(:answer_id => answer.id, :field_type_id => field_id, :field_type_type => "MultiAnswerOption")
      ap.details_text = val
      if ap.changed?
        ap.save
        saved << ap
        result = true
      end
    else
      Array(val).each do |option_id|
        ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(option_id, "MultiAnswerOption") || AnswerPart.new(:answer_id => answer.id, :field_type_id => option_id, :field_type_type => "MultiAnswerOption")
        if question.answer_type.single?
          to_remove += (answer.answer_parts - [ap])
          #for a single_type selection if the option_id != "-1", means that the
          #other field was not selected and so the answer.other_text should be cleared.
          if "-1" != option_id
            answer.other_text = ""
            if answer.changed?
              answer.save
              result = true
            end
          end
        end
        #all existing answer parts that are part of the answer being saved should be preserved, be them new or not.
        saved << ap
        if ap.new_record?
          ap.save
          result = true
        end
        to_remove<< ap if ap.field_type_id.blank?
      end
      if val.blank? #if the value selected is nil, we'll need to remove all or at least the deselected answer_parts
        if field_id #if field_id is defined we'll remove the answer_part that refers to that field_id
          ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "MultiAnswerOption")
          to_remove << ap if ap
        else #if it's not defined just remove all the parts
          to_remove += answer.answer_parts
        end
      end
      if !question.answer_type.single? && question.answer_type.display_type == 1
        to_remove += answer.answer_parts.select{ |answer_part| !saved.include?(answer_part) }
      end
    end
    if !to_remove.empty?
      to_remove.map{ |t| t.delete }
      result = true
    end
    if result && answer.last_editor_id != editor_id
      answer.last_editor_id = editor_id
      answer.save
    end
    [saved, result]
  end
end

# == Schema Information
#
# Table name: multi_answers
#
#  id             :integer          not null, primary key
#  single         :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  other_required :boolean          default(FALSE), not null
#  display_type   :integer          not null
#  original_id    :integer
#
