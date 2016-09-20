module BigQuestionnaireHelper

  def big_questionnaire
    @questionnaire = basic_questionnaire
    5.times { add_regular_section(@questionnaire) }
    root_sections = @questionnaire.sections
    @deeply_nested_section = root_sections[0]
    section = @deeply_nested_section
    5.times do
      section = add_regular_subsection(section)
      5.times { add_text_answer_question(section) }
    end

    loop_source = FactoryGirl.create(:loop_source, questionnaire: @questionnaire)
    loop_item_type1 = FactoryGirl.create(
      :loop_item_type,
      loop_source: loop_source
    )
    loop_item_type2 = FactoryGirl.create(
      :loop_item_type,
      loop_source: loop_source,
      parent: loop_item_type1
    )
    5.times do
      loop_item_name1 = FactoryGirl.create(
        :loop_item_name,
        loop_item_type: loop_item_type1,
        loop_source: loop_source
      )
      loop_item1 = FactoryGirl.create(
        :loop_item,
        loop_item_name: loop_item_name1,
        loop_item_type: loop_item_type1
      )
      5.times do
        loop_item_name2 = FactoryGirl.create(
          :loop_item_name,
          loop_item_type: loop_item_type2,
          loop_source: loop_source
        )
        loop_item2 = FactoryGirl.create(
          :loop_item,
          loop_item_name: loop_item_name2,
          loop_item_type: loop_item_type2
        )
      end
    end
    @looping_section_container = root_sections[1]
    @looping_section1 = add_looping_subsection(@looping_section_container, loop_source, loop_item_type1)
    @looping_section2 = add_looping_subsection(@looping_section1, loop_source, loop_item_type2)
    5.times { add_text_answer_question(@looping_section2) }
  end

end
