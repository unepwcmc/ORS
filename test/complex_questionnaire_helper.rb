module ComplexQuestionnaireHelper

  def basic_questionnaire
    @respondent = FactoryGirl.create(:respondent)
    FactoryGirl.create(:tagging, taggable: @respondent, tag: FactoryGirl.create(:tag))
    questionnaire = FactoryGirl.create(
      :questionnaire,
      user: @respondent,
      last_editor: @respondent
    )
    FactoryGirl.create(:questionnaire_field, questionnaire: questionnaire)
    authorise_user_for_questionnaire @respondent, questionnaire
    questionnaire
  end

  def complex_questionnaire
    @questionnaire = basic_questionnaire
    add_filtering_field(@questionnaire, @questionnaire.user)

    FactoryGirl.create(:alert,
      deadline: FactoryGirl.create(:deadline, questionnaire: @questionnaire),
      reminder: FactoryGirl.create(:reminder)
    )

    @root_section = add_regular_section(@questionnaire)
    #3 text answers
    3.times do
      add_text_answer_question(@root_section)
    end
    @user = FactoryGirl.create(:user)
    answer_to_text @root_section.questions.first

    #add a descendant section
    @root_child = add_regular_subsection(@root_section)
    add_numeric_answer_question(@root_child)
    answer = answer_to_numeric @root_child.questions.first
    FactoryGirl.create(:answer_link, answer: answer)
    FactoryGirl.create(:document, answer: answer)

    @root_section2 = add_regular_section(@questionnaire)
    multi_answer_question = add_multi_answer_question(@root_section2)
    multi_answer_option = multi_answer_question.answer_type.multi_answer_options.first
    @root_section2.update_attributes({
      depends_on_question_id: multi_answer_question.id,
      depends_on_option_id: multi_answer_option.id
    })
    add_range_answer_question(@root_section2)
    add_rank_answer_question(@root_section2)

    @root_child2 = add_regular_subsection(@root_section2)
    # matrix answer with text response
    matrix_question_with_text = add_matrix_answer_question(@root_child2)
    answer_to_matrix matrix_question_with_text

    @root_child3 = add_regular_section(@questionnaire)
    # matrix answer with checkbox response
    matrix_question_with_checkbox = add_matrix_answer_question(@root_child3)
    answer_to_matrix_with_option matrix_question_with_checkbox
    # matrix answer with drop option response
    question_with_drop_down = add_matrix_answer_with_drop_option_question(@root_child3)
    answer_to_matrix_with_drop_option question_with_drop_down

    loop_source = FactoryGirl.create(:loop_source, questionnaire: @questionnaire)
    loop_item_type = FactoryGirl.create(:loop_item_type, loop_source: loop_source)
    loop_item_name = FactoryGirl.create(
      :loop_item_name,
      loop_item_type: loop_item_type,
      loop_source: loop_source
    )
    loop_item = FactoryGirl.create(
      :loop_item,
      loop_item_name: loop_item_name,
      loop_item_type: loop_item_type
    )
    @looping_section = add_looping_subsection(@root_section2, loop_source, loop_item_type)
    FactoryGirl.create(:section_extra,
      section: @looping_section,
      extra: FactoryGirl.create(:extra, loop_item_type: loop_item_type)
    )
    FactoryGirl.create(:user_section_submission_state,
      section: @looping_section,
      user: @questionnaire.user,
      loop_item: loop_item
    )
    @delegation = FactoryGirl.create(
      :delegation,
      questionnaire: @questionnaire,
      user_delegate: FactoryGirl.create(
        :user_delegate, user: @user, delegate: FactoryGirl.create(:user)
      )
    )
    delegation_section = FactoryGirl.create(
      :delegation_section, section: @looping_section, delegation: @delegation
    )
    FactoryGirl.create(
      :delegated_loop_item_name,
      delegation_section: delegation_section,
      loop_item_name: loop_item_name
    )
    question = add_text_answer_question(@looping_section)
    FactoryGirl.create(:question_loop_type, question: question, loop_item_type: loop_item_type)
  end

  def add_regular_section(questionnaire)
    section = FactoryGirl.create(:section, section_type: SectionType::REGULAR)
    FactoryGirl.create(:questionnaire_part, part: section, questionnaire: questionnaire)
    section
  end

  def add_regular_subsection(section)
    subsection = FactoryGirl.create(:section, section_type: SectionType::REGULAR)
    FactoryGirl.create(:questionnaire_part, part: subsection, parent: section.questionnaire_part)
    subsection
  end

  def add_looping_subsection(section, loop_source, loop_item_type)
    subsection = FactoryGirl.create(
      :section,
      section_type: SectionType::LOOPING,
      loop_source: loop_source,
      loop_item_type: loop_item_type
    )
    FactoryGirl.create(:questionnaire_part, part: subsection, parent: section.questionnaire_part)
    subsection
  end

  def add_filtering_field(questionnaire, user)
    filtering_field = FactoryGirl.create(:filtering_field, questionnaire: questionnaire)
    FactoryGirl.create(:user_filtering_field, user: user, filtering_field: filtering_field)
  end

  def add_text_answer_question(section)
    text_answer = FactoryGirl.create(
      :text_answer,
      answer_type_fields_attributes: {0 => {is_default_language: true, language: 'en'}}
    )
    question = FactoryGirl.create(:question, section: section, answer_type: text_answer)
    FactoryGirl.create(:questionnaire_part, part: question, parent: section.questionnaire_part)
    question
  end

  def add_numeric_answer_question(section)
    numeric_answer = FactoryGirl.create(
      :numeric_answer,
      answer_type_fields_attributes: {0 => {is_default_language: true, language: 'en'}}
    )
    question = FactoryGirl.create(:question, section: section, answer_type: numeric_answer)
    FactoryGirl.create(:questionnaire_part, part: question, parent: section.questionnaire_part)
    question
  end

  def add_multi_answer_question(section)
    multi_answer = FactoryGirl.create(
      :multi_answer,
      answer_type_fields_attributes: {0 => {is_default_language: true, language: 'en'}}
    )
    other_field = FactoryGirl.create(:other_field, multi_answer: multi_answer)
    question = FactoryGirl.create(:question, section: section, answer_type: multi_answer)
    FactoryGirl.create(:questionnaire_part, part: question, parent: section.questionnaire_part)
    question
  end

  def add_range_answer_question(section)
    range_answer = FactoryGirl.create(
      :range_answer,
      answer_type_fields_attributes: {0 => {is_default_language: true, language: 'en'}}
    )
    question = FactoryGirl.create(:question, section: section, answer_type: range_answer)
    FactoryGirl.create(:questionnaire_part, part: question, parent: section.questionnaire_part)
    question
  end

  def add_rank_answer_question(section)
    rank_answer = FactoryGirl.create(
      :rank_answer,
      answer_type_fields_attributes: {0 => {is_default_language: true, language: 'en'}}
    )
    question = FactoryGirl.create(:question, section: section, answer_type: rank_answer)
    FactoryGirl.create(:questionnaire_part, part: question, parent: section.questionnaire_part)
    question
  end

  def add_matrix_answer_question(section)
    matrix_answer = FactoryGirl.create(
      :matrix_answer,
      answer_type_fields_attributes: {0 => {is_default_language: true, language: 'en'}}
    )
    question = FactoryGirl.create(:question, section: section, answer_type: matrix_answer)
    FactoryGirl.create(:questionnaire_part, part: question, parent: section.questionnaire_part)
    question
  end

  def add_matrix_answer_with_drop_option_question(section)
    question = add_matrix_answer_question(section)
    FactoryGirl.create(:matrix_answer_drop_option, matrix_answer: question.answer_type)
    question
  end

  def answer_to_question question
    Answer.create(
      user_id: @user.id,
      questionnaire_id: @questionnaire.id,
      question_id: question.id,
      last_editor_id: @user.id
    )
  end

  def answer_to_text question
    answer = answer_to_question(question)
    AnswerPart.create(
      answer: answer,
      answer_text: "Random answer",
      original_language: "en",
      field_type_type: "TextAnswerField",
      field_type_id: question.answer_type.
        text_answer_fields.first.id
    )
    answer
  end

  def answer_to_numeric question
    answer = answer_to_question(question)
    AnswerPart.create(
      answer: answer,
      answer_text: "1.0",
      original_language: "en",
      field_type_type: "NumericAnswer",
      field_type_id: question.answer_type.id
    )
    answer
  end

  def answer_to_matrix question
    answer = answer_to_question(question)
    AnswerPart.create(
      answer: answer,
      answer_text: question.answer_type.
        matrix_answer_queries.first.title,
      original_language: "en",
      field_type_type: "MatrixAnswerQuery",
      field_type_id: question.answer_type.
        matrix_answer_queries.first.id
    )
  end

  def answer_to_matrix_with_option question
    answer = answer_to_question(question)
    answer_part = AnswerPart.create(
      answer: answer,
      original_language: "en",
      field_type_type: "MatrixAnswerQuery",
      field_type_id: question.answer_type.
        matrix_answer_queries.first.id
    )
    FactoryGirl.create(:answer_part_matrix_option,
      answer_part: answer_part,
      matrix_answer_option:  question.answer_type.
        matrix_answer_options.first
    )
    answer
  end

  def answer_to_matrix_with_drop_option question
    answer = answer_to_question(question)
    answer_part = AnswerPart.create(
      answer: answer,
      original_language: "en",
      field_type_type: "MatrixAnswerQuery",
      field_type_id: question.answer_type.
        matrix_answer_queries.first.id
    )
    FactoryGirl.create(:answer_part_matrix_option,
      answer_part: answer_part,
      matrix_answer_drop_option:  question.answer_type.
        matrix_answer_drop_options.first
    )
    answer
  end

end
