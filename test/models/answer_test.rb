require 'test_helper'

class AnswerTest < ActiveSupport::TestCase

  context "1 Questionnaire -> 3 Sections (one of each type) -> 2 Questions -> different answer types" do
    subject{ @questionnaire }
    setup do
      @file = "test/csv/geo_nc.csv"
      @questionnaire = FactoryGirl.create(:questionnaire)  #questionnaire
      current_user = FactoryGirl.create(:user)
      source = FactoryGirl.create(:loop_source, :questionnaire => @questionnaire) #a source
      LoopSource.new_source_from_file source, @questionnaire, @file
      section0 = FactoryGirl.create(:section, :questionnaire => @questionnaire, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type) #looping section
      section01 = FactoryGirl.create(:section, :parent => section0, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type) #looping subsection
      FactoryGirl.create(:section, :parent => section01, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type.children.last) #looping subsection
      FactoryGirl.create(:section, :parent => section01, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type.children.first) #looping subsection
      FactoryGirl.create(:section, :parent => section0, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type.children.first.children.first) #looping subsection
      FactoryGirl.create(:section, :parent => section0, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type.children.first) #looping subsection
      FactoryGirl.create(:section, :parent => section0, :section_type => 0, :loop_source => source, :loop_item_type => source.loop_item_type.children.first.children.last) #looping subsection
      section1 = FactoryGirl.create(:section, :questionnaire => @questionnaire, :section_type => 1) #same_answer_type section
      section2 = FactoryGirl.create(:section, :questionnaire => @questionnaire, :section_type => 2) #regular section
      q1 = FactoryGirl.create(:question, :section => section0, :is_mandatory => true)
      q2 = FactoryGirl.create(:question, :section => section01, :is_mandatory => true)
      q3 = FactoryGirl.create(:question, :section => section0, :is_mandatory => false)
      q4 = FactoryGirl.create(:question, :section => section1, :is_mandatory => true)
      #FactoryGirl.create(:question, :section => section1, :is_mandatory => false)
      #FactoryGirl.create(:question, :section => section2, :is_mandatory => false)
      #FactoryGirl.create(:question, :section => section2, :is_mandatory => true)

      t1 = FactoryGirl.create(:text_answer)
      t1.questions << q1
      t2 = FactoryGirl.create(:text_answer)
      t2.questions << q2
      t3 = FactoryGirl.create(:text_answer)
      t3.questions << q3
      t4 = FactoryGirl.create(:text_answer)
      t4.questions << q4

      @questionnaire.generate!
      #debugger
=begin
      @questionnaire.sections.each do |section|
        Answer.initialize_answers(section.generated_sections, current_user)
      end
=end
    end
  end

end

# == Schema Information
#
# Table name: answers
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  questionnaire_id       :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  other_text             :text
#  question_id            :integer          not null
#  looping_identifier     :string(255)
#  from_dependent_section :boolean          default(FALSE)
#  last_editor_id         :integer
#  loop_item_id           :integer
#  original_id            :integer
#  question_answered      :boolean          default(FALSE)
#
