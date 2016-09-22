class NumericAnswer < ActiveRecord::Base
  attr_accessible :answer_type_fields_attributes, :min_value, :max_value

  ###
  ###   Include Libs
  ###
  include LanguageMethods
  include AnswerTypeMethods

  ###
  ###   Relationships
  ###

  has_many :answer_type_fields, :as => :answer_type, :dependent => :destroy
  accepts_nested_attributes_for :answer_type_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :questions, :as => :answer_type
  has_many  :sections, :as => :answer_type
  #submission side of the tool
  has_many :answer_parts, :as => :field_type #=> each numeric_answer will have an answer_part per user

  ###
  ###   Methods
  ###
  def help_text
    self.answer_type_fields.find_by_is_default_language(true).help_text
  end

  #Saving Numeric Answers: input format of 'identifiers' => 'val'
  #Numeric Answer: "question_id, loop_item_id, answer_type.id (field_id)" => answer(val)
  def self.save_answer val, answer, editor_id, field_id
    saved = nil
    result = false
    if val.present?
      ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "NumericAnswer" ) || AnswerPart.new(:answer_id => answer.id, :field_type_id => field_id, :field_type_type => "NumericAnswer")
      ap.answer_text = val
      if ap.changed?
        ap.save
        saved = ap
        result = true
      end
    else
      ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "NumericAnswer" )
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
# Table name: numeric_answers
#
#  id          :integer          not null, primary key
#  max_value   :integer
#  min_value   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  original_id :integer
#
