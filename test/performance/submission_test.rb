require 'test_helper'
require 'rails/performance_test_help'

class SubmissionTest < ActionDispatch::PerformanceTest
  include ::BigQuestionnaireHelper
  # Refer to the documentation for all available options
  # self.profile_options = { :runs => 5, :metrics => [:wall_time, :memory]
  #                          :output => 'tmp/performance', :formats => [:flat] }

  def setup
    log_in_as @respondent
    big_questionnaire
  end

  def test_questionnaire_home
    get submission_questionnaire_url(@questionnaire)
  end

  def test_nested_section
    get submission_section_url(@deeply_nested_section)
  end

  def test_looping_section
    get submission_section_url(@looping_section_container)
  end
end
