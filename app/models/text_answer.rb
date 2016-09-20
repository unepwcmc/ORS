class TextAnswer < ActiveRecord::Base
  attr_accessible :text_answer_fields_attributes, :answer_type_fields_attributes

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
  has_many :text_answer_fields, :dependent => :destroy
  accepts_nested_attributes_for :text_answer_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :answer_type_fields, :as => :answer_type, :dependent => :destroy
  accepts_nested_attributes_for :answer_type_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  ###
  ###   Validations
  ###
  validates_associated :answer_type_fields

  ###
  ###   Methods
  ###

  #Saving Text Answers: input format of 'identifiers' => 'val'
  #Text Answer: "question_id, loop_item_id, text_answer_field_id(field_id), lang[original, "en"](extra_val)" => answer (val)
  def self.save_answer val, answer, editor_id, field_id, lang
    saved = nil
    result = false
    if val.present?
      ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "TextAnswerField" ) || AnswerPart.new(:answer_id => answer.id, :field_type_id => field_id, :field_type_type => "TextAnswerField")
      ap.answer_text = val if !lang
      if "en" == lang
        ap.answer_text_in_english = val
      elsif "original" == lang
        ap.original_language = val
      end
      if ap.changed?
        ap.save
        saved = ap
        result = true
      end
    else
      ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "TextAnswerField" )
      if ap
        ap.delete
        result = true
      end
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
# Table name: text_answers
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  original_id :integer
#
