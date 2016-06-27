require 'test_helper'

class CloneQuestionnaireTest < ActiveSupport::TestCase

  context "Instantiate a complex questionnaire" do
    setup do
      complex_questionnaire
    end

    should "return 1 questionnaires when find :all is called" do
      assert_equal 1, Questionnaire.all.size
    end

    should "questionnaire should have 3 answers" do
      assert_equal 3, @questionnaire.answers.size
    end

    should "@root_section should have 3 text_answer questions in the questionnaires" do
      assert @questionnaire.sections.include?(@root_section)
      assert_equal 3, @root_section.questions.size
      assert_equal "TextAnswer", @root_section.questions[0].answer_type_type
      assert_equal "TextAnswer", @root_section.questions[1].answer_type_type
      assert_equal "TextAnswer", @root_section.questions[2].answer_type_type
    end

    should "have 1 answer in the @root_section" do
      assert_equal 1, @root_section.questions.map(&:answers).flatten.size
      assert_equal 1, @root_section.questions.map(&:answers).flatten.
        map(&:answer_parts).size
    end

    should "have 1 question and 1 answer for @root_child" do
      assert_equal 1, @root_child.questions.size
      assert_equal 1, @root_child.questions.map(&:answers).flatten.size
      assert_equal 1, @root_child.questions.map(&:answers).flatten.
        map(&:answer_parts).flatten.size
    end

    should "@root_section2 have 1 multi_answer question" do
      assert @questionnaire.sections.include?(@root_section2)
      assert_equal 1, @root_section2.questions.size
      assert_equal "MultiAnswer", @root_section2.questions[0].answer_type_type
    end

    should "have 1 question and 1 answer for @root_child2" do
      assert_equal 1, @root_child2.questions.size
      assert_equal 1, @root_child2.questions.map(&:answers).flatten.size
      assert_equal 1, @root_child2.questions.map(&:answers).flatten.
        map(&:answer_parts).flatten.size
    end

    context "clone the questionnaire with answers" do
      setup do
        CloneQuestionnaire.perform_async(FactoryGirl.create(:user).id, @questionnaire.id,
                                   "http://www.example.com",
                                   true)
        @copy = @questionnaire.copies.first
      end

      should "return 2 questionnaires when find :all is called" do
        assert_equal 2, Questionnaire.all.size
      end

      should "first root section have same number of questions as @root_section" do
        copy_root_section = @copy.sections.first
        assert_equal @root_section.questions.size, copy_root_section.questions.size
        assert_equal "TextAnswer", copy_root_section.questions[0].answer_type_type
        assert_equal "TextAnswer", copy_root_section.questions[1].answer_type_type
        assert_equal "TextAnswer", copy_root_section.questions[2].answer_type_type
      end

      should "@root_section have it's answers properly copied" do
        mapped_section = Section.find(:first, :conditions => {:original_id => @root_section.id})
        assert_equal @root_section.questions.map(&:answers).flatten.size,
          mapped_section.questions.map(&:answers).flatten.size
        assert_equal @root_section.questions.map(&:answers).flatten.map(&:answer_parts).size,
          mapped_section.questions.map(&:answers).flatten.map(&:answer_parts).size
      end

      should "@root_child have it's answers properly copied" do
        mapped_section = Section.find(:first, :conditions => {:original_id => @root_child.id})
        assert_equal @root_child.questions.map(&:answers).flatten.size,
          mapped_section.questions.map(&:answers).flatten.size
        assert_equal @root_child.questions.map(&:answers).flatten.map(&:answer_parts).size,
          mapped_section.questions.map(&:answers).flatten.map(&:answer_parts).size
      end

      should "@root_child2 have it's answers properly copied" do
        mapped_section = Section.find(:first, :conditions => {:original_id => @root_child2.id})
        assert_equal @root_child2.questions.map(&:answers).flatten.size,
          mapped_section.questions.map(&:answers).flatten.size
        assert_equal @root_child2.questions.map(&:answers).flatten.map(&:answer_parts).size,
          mapped_section.questions.map(&:answers).flatten.map(&:answer_parts).size
      end

      should "copy be equal to the original questionnaire" do
        assert_equal @questionnaire.sections.size, @copy.sections.size
        assert_equal @questionnaire.sections.map(&:questions).flatten.size,
          @copy.sections.map(&:questions).flatten.size
        assert_equal @questionnaire.answers.size, @copy.answers.size
        assert_equal @questionnaire.answers.map(&:answer_parts).flatten.size,
          @copy.answers.map(&:answer_parts).flatten.size
      end

      should "copied matrix_answer be equal to the original" do
        matrix_answer = @root_child2.questions.first.answer_type
        mapped_matrix = MatrixAnswer.find(:first, :conditions => {:original_id => matrix_answer.id})

        assert_equal matrix_answer.matrix_answer_queries.size, mapped_matrix.matrix_answer_queries.size
        assert_equal matrix_answer.matrix_answer_queries.first.title,
          mapped_matrix.matrix_answer_queries.first.title
        assert_equal matrix_answer.matrix_answer_options.size, mapped_matrix.matrix_answer_options.size
        assert_equal matrix_answer.matrix_answer_options.first.title,
          mapped_matrix.matrix_answer_options.first.title
      end
    end
  end
end
