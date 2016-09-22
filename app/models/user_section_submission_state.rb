class UserSectionSubmissionState < ActiveRecord::Base

  ###
  ###   Relationships
  ###

  belongs_to :user
  #belongs_to :generated_section
  belongs_to :section
  belongs_to :loop_item

  ###
  ###   Validations
  ###
  validates_uniqueness_of :user_id,  :scope => [:section_id, :looping_identifier]

  #   States
  #
  # 0  - unanswered
  # 1  - mandatory_unanswered (but some answers)
  # 2  - mandatory_answered  (some missing)
  # 3  - all_answered
  # 4  - never visited - or section with no questions

  ###
  ###   Methods
  ###

  def update_state!(section, user, looping_identifier=nil)
    status = section.questions_answered_status(user, looping_identifier)
    self.section_state = status
    self.save!
    status
  end

  def self.submission_state_of(user_id, section_id, looping_identifier=nil)
    user_section_sub_state = UserSectionSubmissionState.find_by_section_id_and_user_id_and_looping_identifier(section_id, user_id, looping_identifier)
    if user_section_sub_state
      user_section_sub_state.section_state.to_i
    else
      SubmissionStatus::DEFAULT
    end
  end
end

# == Schema Information
#
# Table name: user_section_submission_states
#
#  id                 :integer          not null, primary key
#  user_id            :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  section_state      :integer          default(4)
#  section_id         :integer          not null
#  looping_identifier :string(255)
#  loop_item_id       :integer
#  dont_care          :boolean          default(FALSE)
#
