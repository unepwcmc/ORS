class MultiAnswerOption < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  #attr_accessible :option_text, :help_text
  attr_protected :id, :created_at, :updated_at

  ###
  ###   Relationships
  ###
  belongs_to :multi_answer #=> belongs to a multi_answer type answer.
  has_many :answer_parts, :as => :field_type, :dependent => :destroy #=> each multi_answer will have an answer_part per user
  #=>can be the source of dependency for many sections/generated_sections
  has_many :sections, foreign_key: :depends_on_option_id, dependent: :nullify
  has_many :multi_answer_option_fields, :dependent => :destroy
  accepts_nested_attributes_for :multi_answer_option_fields, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true #

  ###
  ###   Validations
  ###
  validates_associated :multi_answer_option_fields

  default_scope  :order => 'sort_index'

  before_create :update_sort_index

  ###
  ###   Methods
  ###
  def option_text language=nil
    result = language ? self.multi_answer_option_fields.find_by_language(language) : nil
    result ? result.option_text : self.multi_answer_option_fields.find_by_is_default_language(true).option_text
  end

  def help_text
    self.multi_answer_option_fields.first.help_text
  end

  def <=>(multi_answer_option)
    sort_index <=> multi_answer_option.sort_index
  end

  private

  def update_sort_index
    last_sort_index = MultiAnswerOption.
      select("sort_index").
      where(multi_answer_id: self.multi_answer_id).
      last.try(:sort_index)

    self.sort_index = (last_sort_index || 0) + 1
  end
end

# == Schema Information
#
# Table name: multi_answer_options
#
#  id              :integer          not null, primary key
#  multi_answer_id :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  details_field   :boolean          default(FALSE)
#  sort_index      :integer          default(0), not null
#  original_id     :integer
#
