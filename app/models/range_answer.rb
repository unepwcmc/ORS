class RangeAnswer < ActiveRecord::Base

  include LanguageMethods
  include AnswerTypeMethods

  ###
  ###   Relationships
  ###
  has_many :questions, :as => :answer_type
  has_many  :sections, :as => :answer_type
  has_many :range_answer_options, :dependent => :destroy, :include => :range_answer_option_fields
  has_many :answer_type_fields, :as => :answer_type, :dependent => :destroy
  accepts_nested_attributes_for :answer_type_fields, :range_answer_options, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  attr_accessible :answer_type_fields_attributes, :range_answer_options_attributes

  validates_associated :answer_type_fields

  #Saving Range Answers, input format of 'identifiers => val
  #Range Answer: "question_id, loop_item_id, option_id(field_id)" => option_id || "" (val)
  #for range answers field_id is the same as val, unless val is blank, which means that it was cleared the answer
  def self.save_answer val, answer, editor_id
    saved = nil
    result = false
    answer.answer_parts.delete_all if answer.answer_parts.count > 1
    if val.present?
      ap = answer.answer_parts.first || AnswerPart.new(:answer_id => answer.id, :field_type_type => "RangeAnswerOption")
      ap.field_type_id = val.to_i
      if ap.changed?
        ap.save
        saved = ap
        result = true
      end
    else #delete existing answer_part
      ap = answer.answer_parts.first
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
# Table name: range_answers
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  original_id :integer
#
