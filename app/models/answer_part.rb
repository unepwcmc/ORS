class AnswerPart < ActiveRecord::Base
  #attr_accessible :answer_text, :other_text, :answer_id, :deleted
  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  belongs_to :answer, touch: true
  belongs_to :field_type, :polymorphic => true
  has_many :answer_part_matrix_options, :dependent => :destroy

  ###
  ###   Methods
  ###

  def <=>(answer_part)
    if sort_index.present?
      sort_index <=> answer_part.sort_index
    else
      created_at <=> answer_part.created_at
    end
  end

end

# == Schema Information
#
# Table name: answer_parts
#
#  id                     :integer          not null, primary key
#  answer_text            :text
#  answer_id              :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  field_type_type        :string(255)
#  field_type_id          :integer
#  details_text           :text
#  answer_text_in_english :text
#  original_language      :string(255)
#  sort_index             :integer
#  original_id            :integer
#
