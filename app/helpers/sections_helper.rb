module SectionsHelper

  def count_all_loop_items(section)
    return 0 if !section.loop_item_type
    return section.loop_item_type.loop_items.size
  end

  def questions_based_on_dependency_of section
    q_from_depending_section = section.depends_on_question.section.questions
    parsed_questions = q_from_depending_section.reject{ |i| ( i.answer_type_type != "MultiAnswer" ) }
    questions_to_select = parsed_questions.map{ |i| [OrtSanitize.white_space_cleanse(i.title).size > 65 ? OrtSanitize.white_space_cleanse(i.title)[0,65]+ "..." : OrtSanitize.white_space_cleanse(i.title), i.id ] }
    options_for_select(questions_to_select, :selected => section.depends_on_question.id)
  end
end
