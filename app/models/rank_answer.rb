class RankAnswer < ActiveRecord::Base

  include LanguageMethods
  include AnswerTypeMethods

  has_many :questions, :as => :answer_type
  has_many  :sections, :as => :answer_type
  has_many :answer_type_fields, :as => :answer_type, :dependent => :destroy
  accepts_nested_attributes_for :answer_type_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #
  has_many :rank_answer_options, :dependent => :destroy, :include => :rank_answer_option_fields
  accepts_nested_attributes_for :rank_answer_options, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  attr_accessible :answer_type_fields_attributes, :maximum_choices,
    :rank_answer_options_attributes

  #Saving Rank Answer: input format of 'identifiers' => val
  #Rank Answer: "question_id, loop_item_id, position(field_id)" => selected_option_id || "" (val)
  def self.save_answer val, answer, editor_id, field_id
    saved = nil
    result = false
    position = field_id #= in the case of Rank Answer Type this refers to the position of the option with id => val
    if val.present?#if there's a value get or create an answer_part for that position and set it's value to be val
      ap = answer.answer_parts.find_by_sort_index(position) || AnswerPart.new(:answer_id => answer.id, :sort_index => position, :field_type_type => "RankAnswerOption")
      ap.field_type_id = val.to_i
      if ap.changed?
        ap.save
        saved = ap
        result = true
      end
    else #if there's no value destroy answer_part if it exists
      ap = answer.answer_parts.find_by_sort_index(position)
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

  def self.to_csv csv, answer_type, s_title, q_title, q_identifier, submitters_ids, answers
    maximum_choices = answer_type.maximum_choices == -1 ? answer_type.rank_answer_options.size : answer_type.maximum_choices
    (0..maximum_choices).each do |option|
      row = Array.new(submitters_ids.size + 3)
      row[0] = s_title
      row[1] = q_title + "[Ranking Answer ##{option+1}]"
      row[2] = q_identifier
      submitters_ids.each_with_index do |val, i|
        index = i + 3
        answer = answers[val.to_s]
        ap = ( answer ? answer.answer_parts.sort[option] : nil )

        timestamp = answer ? " [[timestamp: #{answer.updated_at}]]" : ""
        answer_text = ap ? ap.field_type.option_text : ""
        row[index] = answer_text << timestamp

        if answer
          answer.answer_links.each do |link|
            row[index] << "#URL: #{link.url}"
          end
          answer.documents.each do |document|
            row[index] << "#Doc: #{document.doc.url.split('?')[0]}"
          end
        end
      end
      csv << row
    end
  end
end

# == Schema Information
#
# Table name: rank_answers
#
#  id              :integer          not null, primary key
#  maximum_choices :integer          default(-1)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  original_id     :integer
#
