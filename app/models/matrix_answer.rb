class MatrixAnswer < ActiveRecord::Base

  include LanguageMethods
  include AnswerTypeMethods
  extend EnumerateIt

  has_enumeration_for :display_reply, :with => InputFieldType, :create_helpers => true

  has_many :questions, :as => :answer_type
  has_many :sections, :as => :answer_type
  has_many :answer_type_fields, :as => :answer_type, :dependent => :destroy
  has_many :matrix_answer_queries, :dependent => :destroy, :include => :matrix_answer_query_fields
  has_many :matrix_answer_options, :dependent => :destroy, :include => :matrix_answer_option_fields
  has_many :matrix_answer_drop_options, :dependent => :destroy, :include => :matrix_answer_drop_option_fields
  accepts_nested_attributes_for :matrix_answer_drop_options, :matrix_answer_options, :matrix_answer_queries, :answer_type_fields, :allow_destroy => true,  :reject_if => lambda { |a| a.values.all?(&:blank?) } #

  #For reference ( matrix orientation ) :
  #"Queries (c) x Options (r)" => 0
  #"Options (c) x Queries (r)" => 1

  before_save :remove_unnecessary_drop_options

  attr_accessible :answer_type_fields_attributes, :matrix_orientation,
    :display_reply, :matrix_answer_queries_attributes,
    :matrix_answer_options_attributes, :matrix_answer_drop_options_attributes

  private

  def remove_unnecessary_drop_options
    if 3 != self.display_reply
      self.matrix_answer_drop_options.destroy_all
    end
  end

  ## Saving Matrix Answers, input format of 'identifiers'=> val:
  ## Check-boxes: "question_id, loop_item_id, query_id(field_id), option_id(extra_val) => option_id || "" (val)
  ## Radio-Buttons: "question_id, loop_item_id, query_id(field_id), option_id(extra_val) => option_id || "" (val)
  ## Text-fields: "question_id, loop_item_id, query_id(field_id), option_id(extra_val) => text answer
  ## Drop-Down-Lists: "question_id, loop_item_id, query_id(field_id), option_id(extra_val) => selection (drop_down_option_id) (val)"
  def self.save_answer val, answer, editor_id, field_id, option_id
    saved = []
    result = false
    question = answer.question
    ap = answer.answer_parts.find_by_field_type_id_and_field_type_type(field_id, "MatrixAnswerQuery") || AnswerPart.create(:answer_id => answer.id, :field_type_id => field_id, :field_type_type => "MatrixAnswerQuery")
    saved << ap# if ap.new_record?
    if !val.present?  #delete AnswerPartMatrixOption if it exists and was unselected
      if question.answer_type.radio_button?
        #delete all. Radio_buttons can only have an option selected, so if the value is nil is because there shouldn't be any option selected
        apmo = ap.answer_part_matrix_options
      else
        apmo = ap.answer_part_matrix_options.find_by_matrix_answer_option_id(option_id)
      end
      if apmo
        apmo.delete
        result = true
      end
    else
      if question.answer_type.radio_button?
        ap.answer_part_matrix_options.delete_all if ap.answer_part_matrix_options.count > 1
        apmo = ap.answer_part_matrix_options.first || AnswerPartMatrixOption.new
        apmo.matrix_answer_option_id = val.to_i
      elsif question.answer_type.check_box?
        apmo = ap.answer_part_matrix_options.find_by_matrix_answer_option_id(option_id) || AnswerPartMatrixOption.new
        apmo.matrix_answer_option_id = val.to_i
      elsif question.answer_type.text_field?
        apmo = ap.answer_part_matrix_options.find_by_matrix_answer_option_id(option_id) || AnswerPartMatrixOption.new(:matrix_answer_option_id => option_id)
        apmo.answer_text = val
      elsif question.answer_type.drop_down_list?
        apmo = ap.answer_part_matrix_options.find_by_matrix_answer_option_id(option_id) || AnswerPartMatrixOption.new(:matrix_answer_option_id => option_id)
        apmo.matrix_answer_drop_option_id = val.to_i
      end
      if apmo && apmo.changed?
        apmo.answer_part_id = ap.id
        apmo.save
        result = true
        saved << apmo
        ap.answer_part_matrix_options << apmo unless ap.answer_part_matrix_options.include?(apmo)
      end
    end
    if result && answer.last_editor_id != editor_id
      answer.last_editor_id = editor_id
      answer.save
    end
    [saved, result]
  end

  def self.to_csv csv, answer_type, s_title, q_title, q_identifier, submitters_ids, answers
    answer_type.matrix_answer_queries.each do |maq|

      row = Array.new(submitters_ids.size + 3)
      row[0] = s_title
      row[1] = q_title + "[#{maq.title}]"
      row[2] = q_identifier
      submitters_ids.each_with_index do |val, i|
        index = i + 3
        answer_results = {}
        answer_from_submitter = answers[val.to_s]
        answer_part = answer_from_submitter.answer_parts.find_by_field_type_id(maq.id) if answer_from_submitter
        if answer_part
          answer_part.answer_part_matrix_options.each do |o|
            answer = "x" # Assumes the answer is nil and from a checkbox
            if o.matrix_answer_drop_option
              answer = o.matrix_answer_drop_option.option_text
            elsif o.answer_text
              answer = o.answer_text
            end
            option = o.matrix_answer_option.try(:title)
            answer_results[option] = answer if option
          end
        end

        result = answer_results.map{ |k,v| "#{k}=[#{v}]" }.join('&')
        result += " [[timestamp: #{answer_from_submitter.updated_at}]]" if answer_from_submitter
        row[index] = result
      end
      csv << row
    end
  end
end

# == Schema Information
#
# Table name: matrix_answers
#
#  id                 :integer          not null, primary key
#  display_reply      :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  matrix_orientation :integer          not null
#  original_id        :integer
#
