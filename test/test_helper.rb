ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"

require "minitest/rails"
require "minitest/autorun"
require "minitest/pride"
require "sidekiq/testing"
Sidekiq::Testing.inline!

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

require 'complex_questionnaire_helper'
require 'big_questionnaire_helper'

module ActiveSupport
  class TestCase
    include ::ComplexQuestionnaireHelper
  end
end

require "authlogic/test_case"
include Authlogic::TestCase
activate_authlogic

def log_in_user attributes = {}
  log_in_as FactoryGirl.create(:user, attributes)
end

def log_in_admin_user attributes = {}
  log_in_as FactoryGirl.create(:admin, attributes)
end

def log_in_respondent attributes = {}
  log_in_as FactoryGirl.create(:respondent, attributes)
end

def log_in_as user
  UserSession.create user
end

def irl_respondent_login attributes = {}
  password = (attributes[:password] || 'boats')
  attributes[:password] = password
  attributes[:password_confirmation] = password
  @user = FactoryGirl.create(:respondent, attributes)
  visit '/'
  fill_in 'Email', :with => @user.email
  fill_in 'Password', :with => password
  click_button 'Log in'
  @user
end

def irl_admin_login attributes = {}
  password = (attributes[:password] || 'boats')
  attributes[:password] = password
  attributes[:password_confirmation] = password

  @admin_user = FactoryGirl.create(:admin, attributes)
  visit '/administration'
  fill_in 'Email', :with => @admin_user.email
  fill_in 'Password', :with => password
  click_button 'Log in'
  return @admin_user
end

def fill_in_tinymce id, value
  within_frame(find("##{id}")) {
    editor = page.find_by_id('tinymce')
    editor.set("#{value}\n") #webkit
    # editor.native.send_keys(value) #selenium
  }
end

def factory_section_questionnaire attributes={}
  questionnaire = attributes[:questionnaire] || factory_questionnaire(
    :attributes => attributes)
  title = (attributes[:title] || "My section Title")
  section = FactoryGirl.create(:section,
    :section_type => SectionType.list[2]
  )
  questionnaire_part = FactoryGirl.create(:questionnaire_part,
    :part => section
  )
  section_field = FactoryGirl.create(:section_field,
    section: section,
    :is_default_language => true,
    :tab_title => title,
    :title => title
  )
  questionnaire.questionnaire_parts << questionnaire_part
  return section, questionnaire
end

def factory_questionnaire attributes={}
  user = attributes[:user] || FactoryGirl.create(:user)
  questionnaire = attributes[:questionnaire] || FactoryGirl.create(
    :questionnaire, user: user, last_editor: user)
  FactoryGirl.create(
    :questionnaire_field,
    :language => "en",
    questionnaire: questionnaire
  )
  questionnaire.last_editor = user
  questionnaire.save!
  questionnaire
end

def factory_text_answer
  text_answer = TextAnswer.new
  text_answer.text_answer_fields << TextAnswerField.new
  text_answer
end

def create_multi_answer_from_type input_type
  case input_type
  when :radio_button
    single = true
    display_type = 0
  when :checkbox
    single = false
    display_type = 0
  when :dropdown
    single = true
    display_type = 1
  when :multi_dropdown
    single = false
    display_type = 1
  else
    return nil
  end

  answer_type_fields = [FactoryGirl.create(:answer_type_field)]

  return FactoryGirl.create(:multi_answer,
    :answer_type_fields => answer_type_fields,
    :single => single,
    :display_type => display_type
  )
end

def factory_multi_answer_question section, questionnaire, input_type
  multi_answer = create_multi_answer_from_type input_type

  multi_answer_option_1 = MultiAnswerOption.new
  multi_answer_option_1.multi_answer_option_fields << FactoryGirl.build(
    :multi_answer_option_field, :option_text => "Hats")

  multi_answer_option_2 = MultiAnswerOption.new
  multi_answer_option_2.multi_answer_option_fields << FactoryGirl.build(
    :multi_answer_option_field, :option_text => "Boats")

  multi_answer.multi_answer_options = [
    multi_answer_option_1, multi_answer_option_2
  ]

  multi_answer.save

  return factory_question_for_section section, questionnaire, multi_answer
end

def factory_question_for_section section, questionnaire, answer_type
  question = FactoryGirl.create(:question,
    is_mandatory: "0",
    answer_type_type: answer_type.class.name,
    section: section
  )

  question_field = FactoryGirl.create(:question_field,
    is_default_language: true, question: question)
  question.answer_type = answer_type

  question.answer_type.answer_type_fields = [
    FactoryGirl.create(:answer_type_field)
  ]

  question.save!

  FactoryGirl.create(:questionnaire_part,
    part_id: question.id,
    part_type: "Question",
    questionnaire_id: questionnaire.id,
    parent: section.questionnaire_part
  )

  question
end

def authorise_user_for_questionnaire user, questionnaire
  questionnaire.activate!

  authorized_submitter = AuthorizedSubmitter.new
  authorized_submitter.user = user
  authorized_submitter.questionnaire = questionnaire

  authorized_submitter.language = questionnaire.language
  authorized_submitter.status = SubmissionStatus::UNDERWAY
  authorized_submitter.save!
end

def create_matrix_answer_option title
  matrix_answer_option = FactoryGirl.build :matrix_answer_option
  # `matrix_answer_option_fields` is an array because we could have different
  # languages for the same answer option.
  matrix_answer_option.matrix_answer_option_fields = [
    FactoryGirl.create(:matrix_answer_option_field, :title => title) ]
  matrix_answer_option.save!
  matrix_answer_option
end

def create_matrix_answer_query title
  matrix_answer_query = FactoryGirl.build :matrix_answer_query
  # `matrix_answer_query_fields` is an array because we could have different
  # languages for the same answer query.
  matrix_answer_query.matrix_answer_query_fields = [
    FactoryGirl.create(:matrix_answer_query_field, :title => title) ]
  matrix_answer_query.save!
  matrix_answer_query
end

def factory_matrix_question section, questionnaire
  answer_type_fields = [FactoryGirl.create(:answer_type_field)]

  matrix_answer = FactoryGirl.build :matrix_answer,
    :answer_type_fields => answer_type_fields

  ["query a", "query b"].each { |title|
    matrix_answer.matrix_answer_queries << create_matrix_answer_query(title) }

  ["option a", "option b"].each { |title|
    matrix_answer.matrix_answer_options << create_matrix_answer_option(title) }

  matrix_answer.save!

  factory_question_for_section section, questionnaire, matrix_answer
end

def factory_loop_source
end

def factory_questionnaire_deadline questionnaire
  deadline = FactoryGirl.create(:deadline,
    :questionnaire => questionnaire
  )
  questionnaire.save!
  deadline
end

def create_respondents
  respondents = []
  respondent = FactoryGirl.create(:respondent_role)
  (1..5).each do |n|
    user = FactoryGirl.create(:user,
      :roles => [respondent],
      :first_name => "First_name_#{n}",
      :last_name => "Last_name_#{n}"
    )
    respondents << user
  end
  respondents
end

def create_answer question, user, field_type, answered = false
  answer = FactoryGirl.create(:answer, user: user, question: question, questionnaire: question.questionnaire, question_answered: answered)
  FactoryGirl.create(:answer_part, answer: answer, field_type: field_type)
  answer
end

def factory_questionnaire_respondents questionnaire
  create_respondents.each do |rs|
    authorise_user_for_questionnaire rs, questionnaire
  end
end

# TODO: maybe this should not live here, due to its assertions...
# Moved it here for now because it is shared across multiple tests.
def visit_questionnaire_submission_page questionnaire
  visit submission_questionnaire_path(questionnaire)

  assert page.has_content?(questionnaire.questionnaire_fields.first.title)
  assert page.has_content?("Submit questionnaire")
end
