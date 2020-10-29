class AuthorizedSubmitter < ActiveRecord::Base

  ###
  ###   Include Libs
  ###
  include LanguageMethods
  extend EnumerateIt

  has_enumeration_for :status, :with => SubmissionStatus, :create_helpers => true

  ###
  ###   Relationships
  ###
  belongs_to :user
  belongs_to :questionnaire

  ###
  ###   Validations
  ###
  validates_uniqueness_of :user_id, :scope => :questionnaire_id

  attr_accessible :user_id, :questionnaire_id

  ###
  ###   Methods
  ###

  # Authorizes an array of users to access the submission side of a questionnaire
  # If the authorization record is new or the existing authorization record has a status of "NOT_STARTED", send the Authorization job to Sidekiq's queue.
  # If the authorization record has a status of Halted set the status to Underway.
  # Params:
  #   users_ids: user id's to authorize
  #   questionnaire: the questionnaire to which the users will be authorized
  # Return:
  #   users: array of users that were authorized
  def self.authorize_from_array_of_users(users_ids, questionnaire, url, disable_emails)
    users = []
    Array(users_ids).each do |user_id,| #users_ids is an hash with "user_id => user_id", coming from a set of check boxes
      user = User.find(user_id.to_i)
      if user
        language = questionnaire.available_languages.include?(user.language) ? user.language : questionnaire.language
        authorized_submitter = AuthorizedSubmitter.find_or_initialize_by_user_id_and_questionnaire_id(:user_id => user.id, :questionnaire_id => questionnaire.id)
        if authorized_submitter.new_record? || authorized_submitter.status == SubmissionStatus::NOT_STARTED
          if authorized_submitter.new_record?
            authorized_submitter.language = language
            authorized_submitter.save
          end
          users += [user]
          @jid = AuthorizationBuilder.perform_async(user.id, questionnaire.id, url, disable_emails)
        elsif authorized_submitter.status == SubmissionStatus::HALTED
          users += [user]
          authorized_submitter.status = SubmissionStatus::UNDERWAY
          authorized_submitter.save
        end
      end
    end
    users
  end

  # Halts any existing authorizations for an array of Users.
  # Params:
  #   users_ids: users id's to de-authorize
  #   questionnaire: the questionnaire from which the users will be de-authorized
  # Return:
  #   @users: array of users that were de-authorized
  def self.remove_authorization_from_array_of_users(users_ids, questionnaire, url)
    users = []
    Array(users_ids).each do |user_id,| #users_ids is an hash with "user_id => user_id", coming from a set of checkboxes
      user = User.find(user_id.to_i)
      if user
        authorized_submitter = questionnaire.authorized_submitters.find_by_user_id(user_id)
        next if !authorized_submitter
        users += [user]
        if authorized_submitter.status != SubmissionStatus::NOT_STARTED
          authorized_submitter.status = SubmissionStatus::HALTED
          authorized_submitter.save
        else
          Sidekiq::Status.cancel @jid
          authorized_submitter.destroy
        end
      end
    end
    users
  end

  def update_answered_questions_value! questionnaire, user
    self.answered_questions = Answer.find_all_by_questionnaire_id_and_user_id_and_from_dependent_section(questionnaire.id, user.id, false).count
    self.save!
  end

  def count_available_questions
    self.total_questions = self.questionnaire.count_questions_available_for self.user
    self.save!
  end
end

# == Schema Information
#
# Table name: authorized_submitters
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  questionnaire_id       :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  status                 :integer          default(0)
#  language               :string(255)      default("en")
#  total_questions        :integer          default(0)
#  answered_questions     :integer          default(0)
#  requested_unsubmission :boolean          default(FALSE)
#
