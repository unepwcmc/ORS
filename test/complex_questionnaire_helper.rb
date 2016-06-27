module ComplexQuestionnaireHelper
  def complex_questionnaire
    @questionnaire = FactoryGirl.create(:questionnaire)
    @questionnaire.questionnaire_fields << FactoryGirl.create(:questionnaire_field)
    @root_section = FactoryGirl.create(:section, :section_type => SectionType::REGULAR)
    FactoryGirl.create(:questionnaire_part, :part => @root_section, :questionnaire_id => @questionnaire.id)
    #3 text answers
    3.times do
      text_answer = FactoryGirl.create(:text_answer, :answer_type_fields_attributes => {0 => {is_default_language: true}})
      question = FactoryGirl.create(:question, :section_id => @root_section.id,
                        :answer_type => text_answer)
      FactoryGirl.create(:questionnaire_part, :part => question,
              :parent_id => @root_section.questionnaire_part.id)
    end
    @user = FactoryGirl.create(:user)
    answer_to_text @root_section.questions.first

    #add a descendant section
    @root_child = FactoryGirl.create(:section, :section_type => SectionType::REGULAR)
    FactoryGirl.create(:questionnaire_part, :part => @root_child, :parent_id => @root_section.questionnaire_part.id)
    1.times do
      numeric_answer = FactoryGirl.create(:numeric_answer, :answer_type_fields_attributes => {0 => {is_default_language: true}})
      question = FactoryGirl.create(:question, :section_id => @root_child.id,
                        :answer_type => numeric_answer)
      FactoryGirl.create(:questionnaire_part, :part => question,
              :parent_id => @root_child.questionnaire_part.id)
    end
    answer_to_numeric @root_child.questions.first

    @root_section2 = FactoryGirl.create(:section, :section_type => SectionType::REGULAR)
    FactoryGirl.create(:questionnaire_part, :part => @root_section2, :questionnaire_id => @questionnaire.id)

    1.times do
      multi_answer = FactoryGirl.create(:multi_answer, :answer_type_fields_attributes => {0 => {is_default_language: true}})
      question = FactoryGirl.create(:question, :section_id => @root_section2.id,
                         :answer_type => multi_answer)
      FactoryGirl.create(:questionnaire_part, :part => question,
              :parent_id => @root_section2.questionnaire_part.id)
    end

    @root_child2 = FactoryGirl.create(:section, :section_type => SectionType::REGULAR)
    FactoryGirl.create(:questionnaire_part, :part => @root_child2, :parent_id => @root_section2.questionnaire_part.id)
    1.times do
      matrix_answer = FactoryGirl.create(:matrix_answer, :answer_type_fields_attributes => {0 => {is_default_language: true}})
      question = FactoryGirl.create(:question, :section_id => @root_child2.id,
                        :answer_type => matrix_answer)
      FactoryGirl.create(:questionnaire_part, :part => question,
              :parent_id => @root_child2.questionnaire_part.id)
    end
    answer_to_matrix @root_child2.questions.first
  end

  def answer_to_text question
    Answer.create(:user_id => @user.id,
      :questionnaire_id => @questionnaire.id,
      :question_id => question.id,
      :last_editor_id => @user.id,
      :answer_parts => [
        AnswerPart.create(
          :answer_text => "Random answer",
          :original_language => "en",
          :field_type_type => "TextAnswerField",
          :field_type_id => question.answer_type.
            text_answer_fields.first.id
        )
      ])
  end

  def answer_to_numeric question
    Answer.create(:user_id => @user.id,
      :questionnaire_id => @questionnaire.id,
      :question_id => question.id,
      :last_editor_id => @user.id,
      :answer_parts => [
        AnswerPart.create(
          :answer_text => "1.0",
          :original_language => "en",
          :field_type_type => "NumericAnswer",
          :field_type_id => question.answer_type.id
        )
      ])
  end

  def answer_to_matrix question
    Answer.create(:user_id => @user.id,
      :questionnaire_id => @questionnaire.id,
      :question_id => question.id,
      :last_editor_id => @user.id,
      :answer_parts => [
        AnswerPart.create(
          :answer_text => question.answer_type.
            matrix_answer_queries.first.title,
          :original_language => "en",
          :field_type_type => "MatrixAnswerQuery",
          :field_type_id => question.answer_type.
            matrix_answer_queries.first.id
        )
      ])
  end
end
