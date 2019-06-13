class User < ActiveRecord::Base
  require 'csv'
  ###
  ###   Before something, do something
  ###
  before_validation :downcase_email

  ###
  ###   Include Libs
  ###
  include LanguageMethods

  ###
  ###   Plugins/Gems declarations
  ###

  acts_as_taggable_on :groups
  acts_as_authentic do |c|
    c.login_field = 'email'
    #c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.disable_perishable_token_maintenance true
    c.validates_format_of_login_field_options = { with: Authlogic::Regex.email_nonascii }
    c.merge_validates_length_of_password_field_options({:minimum => 5})
  end

  ###
  ###   Relationships
  ###

  has_many :questionnaires, dependent: :restrict #=> as creator of questionnaires
  has_many :edited_questionnaires, :class_name => "Questionnaire", :foreign_key => :last_editor_id, dependent: :nullify #=>last editor of questionnaires
  has_many :authorized_submitters, :dependent => :destroy #=> relation regarding the questionnaires that the user is authorized to answer to.
  #a questionnaire is considered to be available to the user if there's an AuthorizedSubmitter record for the user and that questionnaire, and the stauts of that AuthorizedSubmitterRecord is not 'SubmissionStatus::HALTED'
  has_many :available_questionnaires, :through => :authorized_submitters, :source => :questionnaire, :conditions => {:authorized_submitters => {:status => [SubmissionStatus::NOT_STARTED, SubmissionStatus::UNDERWAY, SubmissionStatus::SUBMITTED]}}#=> questionnaires that has available to answer
  has_many :answers, :dependent => :destroy #=> all of user's answers
  has_many :answered_questionnaires, :through => :answers, :source => :questionnaire, :uniq => true
  has_many :edited_answers, :class_name => 'Answer', :foreign_key => :last_editor_id, dependent: :nullify
  has_many :documents, :through => :answers
  has_many :assignments, :dependent => :destroy #=> many-to-many relation with roles
  has_many :roles, :through => :assignments
  has_many :delegate_text_answers

  has_many :submission_states, :class_name => "UserSectionSubmissionState", dependent: :destroy #=> the state of submission of a specific section

  has_many :user_filtering_fields, :dependent => :destroy #=> user can have many filtering fields

  belongs_to :creator, :class_name => "User" #=> Users can be created by other users
  has_many :created_users, :class_name => "User", :foreign_key => :creator_id #=> Users (namely Admin's) can create many users
  # creator_id => 0 if Registered by self, id if created by another user
  has_many :user_delegates, :dependent => :destroy
  has_many :delegates, :through => :user_delegates, :source => :delegate
  has_many :delegations, :through => :user_delegates
  has_many :user_delegators, :class_name => "UserDelegate", :foreign_key => :delegate_id, :dependent => :destroy
  has_many :delegators, :through => :user_delegators, :source => :user
  has_many :delegated_tasks, :through => :user_delegators, :source => :delegations
  has_many :pdf_files, :dependent => :destroy
  #Errors
  has_many :persistent_errors, :dependent => :destroy

  ###
  ###   Named Scopes
  ###

  scope :last_created, lambda { |num| {:limit => num, :order => 'created_at DESC'} }
  scope :submitters, joins: :roles, conditions: ['roles.name = ?', "respondent"]
  scope :administrators, joins: :roles, conditions:  ['roles.name = ?', 'admin']
  # users with submitter role that have not yet been authorized to answer a specific questionnaire
  # excluding is a condition: users.id NOT IN (set of id's of authorized submitters for the questionnaire)
  scope :available_submitters, lambda { |excluding| {joins: :roles, conditions: ['roles.name = ? AND '+ excluding, "respondent"]} }
  scope :delegates, joins: :roles, conditions: ['roles.name = ? OR roles.name = ?', 'delegate', 'super_delegate']

  ###
  ###   Validations
  ###
  validates_presence_of :first_name, :last_name, :language
  validate :redundant_roles

  attr_accessible :creator_id, :first_name, :last_name, :language, :email,
    :category, :password, :password_confirmation, :role_ids,
    :single_access_token, :region, :country, :perishable_token,
    :user_delegates_attributes, :user_delegators_attributes,
    :has_api_access

  accepts_nested_attributes_for :user_delegates, :user_delegators

  ###
  ###   Methods
  ###

  #=> auxiliary method that converts the user roles' names into symbols to facilitate comparison in the "role?" method.
  def roles_to_sym
    roles.map do |role|
      role.name.underscore.to_sym
    end
  end

  #=>check if a user as a specified role
  # params: role
  def role? role
    roles_to_sym.include? role
  end

  def authorized_to_answer? questionnaire, user_delegate = nil, respondent_id = nil
    authorization = false
    if (is_admin_or_respondent_admin?) && respondent_id
      authorization = AuthorizedSubmitter.find_by_questionnaire_id_and_user_id(questionnaire.id, respondent_id)
      return authorization if authorization
    end
    if self.role?(:respondent)
      authorization = AuthorizedSubmitter.find_by_questionnaire_id_and_user_id(questionnaire.id, self.id)
      return authorization if authorization
    end
    if !authorization && is_delegate?
      delegation = user_delegate.present? ? self.delegated_tasks.find_by_questionnaire_id_and_user_delegate_id(questionnaire.id, user_delegate) : self.delegated_tasks.find_by_questionnaire_id(questionnaire.id)
      return false if !delegation
      return delegation.user.authorized_to_answer?(questionnaire)
    end
    authorization
  end

  #fill the authorization object that will be used in the pages for questionnaire submission
  #object can be questionnaire, section, or even question
  def authorization_for object, user_delegate = nil, respondent_id = nil
    authorization = {}
    authorization[:error_message] = nil
    #as the object might not be a questionnaire itself it is necessary to do this check and load the questionnaire
    questionnaire = object.is_a?(Questionnaire) ? object : object.questionnaire
    if questionnaire.closed?
      authorization[:error_message] = "questionnaire_closed"
      return authorization
    elsif questionnaire.inactive?
      authorization[:error_message] = "questionnaire_not_available"
      return authorization
    end
    #load and check authorization
    aux = self.authorized_to_answer?(questionnaire, user_delegate, respondent_id)
    if !aux
      authorization[:error_message] = "not_authorized"
      return authorization
    elsif aux.status == SubmissionStatus::SUBMITTED
      authorization[:error_message] = "questionnaire_submitted"
      return authorization
    elsif aux.status == SubmissionStatus::NOT_STARTED
      authorization[:error_message] = "questionnaire_not_available"
      return authorization
    end
    #set the authorization data
    authorization[:is_closed] = questionnaire.closed?
    authorization[:delegation_enabled] = questionnaire.delegation_enabled
    authorization[:translator_visible] = questionnaire.translator_visible
    authorization[:status] = aux.status
    authorization[:language] = aux.language
    authorization[:language_full_name] = aux.language_full_name
    authorization[:user] = aux.user
    #get the delegation details if the user is a delegate and it has been delegated with this questionnaire
    if is_delegate?
      #no check for the existence of delegation, because that is checked in the 'is_authorized_to_answer?' method
      delegation = user_delegate ? self.delegated_tasks.find_by_questionnaire_id_and_user_delegate_id(questionnaire, user_delegate) : self.delegated_tasks.find_by_questionnaire_id(questionnaire)
      #if the sections aren't defined the delegate can answer the whole questionnaire
      #otherwise the information needs to be passed to the view to disabled the non-delegated sections
      #TODO: should there be any specific behavior in case a user is both a delegate and a respondent?
      if delegation && !delegation.delegation_sections.empty?
        authorization[:sections] = {}
        delegation.delegation_sections.each do |delegation_section|
          authorization[:sections][delegation_section.section_id.to_s] = []
          if delegation_section.loop_item_names.present?
            delegation_section.loop_item_names.each do |loop_item_name|
              authorization[:sections][delegation_section.section_id.to_s] << loop_item_name.id
            end
          end
        end
      end
    end
    authorization
  end

  def add_or_update_filtering_fields(fields)
    Array(fields).each do |field_id, field_value|
      if field_value.present?
        obj = UserFilteringField.find_or_initialize_by_user_id_and_filtering_field_id(self.id, field_id)
        if !obj.field_value || obj.field_value.downcase != field_value.downcase
          obj.field_value = field_value
          obj.save
        end
      else
        obj = UserFilteringField.find_by_user_id_and_filtering_field_id(self.id, field_id)
        obj.delete if obj
      end
    end
  end

  # Params:
  #   users_ids: hash with user_id => user_id, pairs
  #   group: group name
  # Returns:
  #   @users: array with the users that were actually added to the group
  def self.add_users_to_group(users_ids, group)
    @users = []
    Array(users_ids).each do |user_id, |
      user = User.find(user_id.to_i)
      if user
        user.group_list = user.group_list + [group]
        user.save!
        @users += [user] #=> list of "really" added users (for UI purposes)
      end
    end
    @users
  end

  def full_name
    self.first_name + " " + self.last_name
  end

  def authorized_submitter_of? questionnaire
    self.available_questionnaires.include?(questionnaire)
  end

  def submitted?(questionnaire)
    auth = self.authorized_submitters.find_by_questionnaire_id(questionnaire.id)
    return true if auth.submitted?
    false
  end

  def get_filtering_fields_values_for questionnaire
    values = []
    questionnaire.filtering_fields.each do |field|
      obj = self.get_filtering_field_value(field)
      unless obj == "Not defined"
        values << obj
      end
    end
    values
  end

  def get_filtering_field_value filtering_field
    obj = self.user_filtering_fields.find_by_filtering_field_id(filtering_field.id)
    (obj && obj.field_value) ? obj.field_value : "Not defined"
  end

  def <=>user
    self.full_name <=> user.full_name
  end

  #get a user's delegates that have been delegated with a specific section
  #
  # return: Array of UserDelegate objects
  def delegates_for_section section, loop_item_name_id=nil
    self.user_delegates.select{ |ud| Delegation.covers_section?(ud.delegations.find_by_questionnaire_id(section.questionnaire.id), section, loop_item_name_id) } - self.delegates_for_questionnaire(section.questionnaire)
  end

  #
  # return: Array of UserDelegate objects
  def delegates_for_questionnaire questionnaire
    self.user_delegates.select{ |ud| ud.delegations.find_by_questionnaire_id(questionnaire.id) && !ud.delegations.find_by_questionnaire_id(questionnaire.id).delegation_sections.any? }
  end

  def parse_uploaded_list file, status, url, send_welcome_email=false
    # keep track of the errors
    status[:errors] = []

    # keep track of the line and column being analised, for error questionnaireing.
    status[:line] = 0
    status[:users] = []
    status[:users_passwords] = {}

    # read the file into a table
    begin
      if File.open(file, &:readline).match(/;/) == nil
        separator = ','
      else
        separator = ';'
      end

      table = CSV.read(file, {
        :quote_char => '"',
        :col_sep =>separator,
        :row_sep =>:auto}
      ) #, :headers => :first_row})
    rescue => e
      status[:errors] << e.message
      return false
    end

    languages = ["ar", "en", "fr", "es", "ru", "zh"]
    role_ids = [Role.find_by_name("respondent").id]

    table.each do |row|
      status[:line] += 1
      row_as_a = row.to_a

      first_name = row_as_a[0].present? ? row_as_a[0].squeeze(" ").strip : ""
      last_name = row_as_a[1].present? ? row_as_a[1].squeeze(" ").strip : ""
      email = row_as_a[2].present? ? row_as_a[2].squeeze(" ").strip : nil
      country = row_as_a[3].present? ? row_as_a[3].squeeze(" ").strip : nil
      region = row_as_a[4].present? ? row_as_a[4].squeeze(" ").strip : nil
      the_password = row_as_a[5].present? ? row_as_a[5].squeeze(" ").strip : "new_user_password"
      language = row_as_a[6].present? && languages.include?(row_as_a[6].squeeze(" ").strip) ?  row_as_a[6].squeeze(" ").strip : "en"
      category = row_as_a[7].present? && ["Scientific Authority", "Management Authority"].include?(row_as_a[7].squeeze(" ").strip) ? row_as_a[7].squeeze(" ").strip : "Other"
      group = row_as_a[8].present? ? row_as_a[8].squeeze(" ").strip : nil

      if !email.nil? && !User.find_by_email(email)
        new_user = User.create(
          :first_name => first_name, :last_name => last_name, :email => email,
          :country => country, :region => region,
          :language => language,
          :password => the_password, :password_confirmation => the_password,
          :role_ids => role_ids, :category => category
        )

        if new_user
          if group
            new_user.group_list = [group]
            new_user.save!
          end
          self.created_users << new_user
          status[:users] << new_user

          if send_welcome_email
            UserMailer.user_registration(
              new_user,
              (row_as_a[3].squeeze(" ").strip || "new_user_password"),
              url
            ).deliver
          end
        end
      else
        status[:errors] << "Line: #{status[:line]}: #{email.nil? ? "Email not provided." : "There is already a user in the system with the following email address: #{email}"}"
      end
    end

    status
  end

  #Check if user has answered any question that is descendant of section for a specific loop_item in a specific branch
  #of a looping section
  def answered_anything_here section, looping_identifier
    self.answers.find_all_by_looping_identifier(looping_identifier).each do |answer|
      if ( answer.answer_parts.any? || answer.other_text.present? ) && answer.question && section.is_ancestor_of?(answer.question)
        return true
      end
    end
    false
  end

  def update_authorizations
    self.authorized_submitters.each do |s|
      if s.language != self.language && s.questionnaire.available_languages.include?(self.language)
        s.language = self.language
        s.save
      end
    end
  end

  def is_authorized_to_answer? section, user_delegate_id
    delegated = section.is_delegated?(user_delegate_id)
    delegated || (!delegated && authorized_to_answer?(section.questionnaire, user_delegate_id))
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.deliver_password_reset_instructions(self).deliver
  end

  def can_edit_delegate_text_answer?(section, user_delegate)
    questionnaire_id = section.questionnaire.id
    if self.role?(:delegate) && user_delegate
      delegation = user_delegate.delegations.
        find_by_questionnaire_id_and_user_delegate_id(questionnaire_id, user_delegate.id)
      return section.is_or_has_parents_delegated_to?(delegation) ||
           delegation.try(:can_view_and_edit_all_questionnaire?)
    end
    return false
  end

  def add_delegations(delegations)
    delegations.each do |key, value|
      user_delegate = UserDelegate.create(user_id: value["user_id"], delegate_id: self.id)
      questionnaire_id = value["delegations_attributes"].first["questionnaire_id"]
      Delegation.create(questionnaire_id: questionnaire_id, user_delegate_id: user_delegate.id)
    end
  end

  def is_delegate?
    role?(:delegate) || role?(:super_delegate)
  end

  def is_admin_or_respondent_admin?
    role?(:admin) || role?(:respondent_admin)
  end

  def self.unassigned_delegates(respondent)
    delegate_ids = delegates.map(&:id)
    where(id: delegate_ids - respondent.delegates.map(&:id))
  end

  def admin_can_submit_questionnaire?(respondent)
    is_admin_or_respondent_admin? && (respondent && respondent.role?(:respondent))
  end

  def role_can_edit_respondents_answers?
    is_admin_or_respondent_admin? || role?(:super_delegate)
  end

  private
    def downcase_email
      self.email.downcase!
    end

    def redundant_roles
      if ((role?(:admin) && role?(:respondent_admin)) ||
        (role?(:delegate) && role?(:super_delegate)))
        errors.add(:roles, I18n.t('user_new.redundant_roles'))
      end
    end
end

# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  email               :string(255)      not null
#  persistence_token   :string(255)      not null
#  crypted_password    :string(255)      not null
#  password_salt       :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  login_count         :integer          default(0), not null
#  failed_login_count  :integer          default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  perishable_token    :string(255)      not null
#  single_access_token :string(255)      not null
#  first_name          :string(255)
#  last_name           :string(255)
#  creator_id          :integer          default(0)
#  language            :string(255)      default("en")
#  category            :string(255)
#  region              :text             default("")
#  country             :text             default("")
#
