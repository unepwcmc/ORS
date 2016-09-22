require 'test_helper'
require 'rails/performance_test_help'

class QuestionnaireTest < ActionDispatch::PerformanceTest
  include ::BigQuestionnaireHelper

  def setup
    big_questionnaire
  end

  def test_sections_to_display_in_tab
    @questionnaire.sections_to_display_in_tab
  end
end
