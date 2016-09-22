require 'test_helper'

class SectionsControllerTest < ActionController::TestCase

  def setup
    @respondent = FactoryGirl.create(:respondent)
    @delegate = FactoryGirl.create(:delegate)
    admin_user = FactoryGirl.create(:admin)
    @section, @questionnaire = factory_section_questionnaire(
      :user => admin_user
    )
    AuthorizedSubmitter.authorize_from_array_of_users([@respondent.id], @questionnaire, 'http://www.example.com', nil)
    text_answer = factory_text_answer
    @question = factory_question_for_section @section, @questionnaire, text_answer
    @field_type = text_answer.text_answer_fields.first
    @looping_id = 0
    user_delegate = FactoryGirl.create(:user_delegate, user: @respondent, delegate: @delegate)
    FactoryGirl.create(:delegation, user_delegate: user_delegate, questionnaire: @questionnaire)
    @questionnaire.activate!
  end

  context "question not marked as answered" do

    setup do
      @answer = create_answer(@question, @respondent, @field_type)
      @answers = {"#{@question.id}_#{@looping_id}_#{@field_type.id}" => "Some text"}
      @delegate_answers = {"#{@question.id}_#{@looping_id}" => {delegate_answer_id: 'new', answer_id: @answer.id, value: 'Delegate text'}}
    end

    should "respondent should update answer when question has not been marked as answered" do
      controller.stubs(current_user: @respondent)
      xhr :post, :save_answers, format: "js", section: @section.id, answers: @answers, auto_save: 1

      assert_equal "Some text", @answer.answer_parts(true).first.answer_text
    end

    should "delegate should update answer when question has not been marked as answered" do
      controller.stubs(current_user: @delegate)

      xhr :post, :save_answers, format: "js", section: @section.id, delegate_text_answers: @delegate_answers, auto_save: 1

      assert_equal "Delegate text", @answer.delegate_text_answers.find_by_user_id(@delegate.id).answer_text
    end
  end

  context "question marked as answered" do

    setup do
      @answer = create_answer(@question, @respondent, @field_type, true)
      @answers = {"#{@question.id}_0_#{@field_type.id}" => "Some text"}
      @delegate_answers = {"#{@question.id}_#{@looping_id}" => {delegate_answer_id: 'new', answer_id: nil, value: 'Delegate text'}}
    end

    should "respondent should not update answer when question has been marked as answered" do
      controller.stubs(current_user: @respondent)

      xhr :post, :save_answers, format: "js", section: @section.id, answers: @answers, auto_save: 1

      assert_equal nil, @answer.answer_parts(true).first.answer_text
    end

    should "delegate should not update answer when question has been marked as answered" do
      controller.stubs(current_user: @delegate)

      xhr :post, :save_answers, format: "js", section: @section.id, delegate_text_answers: @delegate_answers, auto_save: 1

      assert_equal 0, @answer.delegate_text_answers.count
    end
  end

end
