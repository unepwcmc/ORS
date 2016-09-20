require 'test_helper'

class QuestionnaireTest < ActiveSupport::TestCase

  context "3 Questionnaires, 2 recent ones and 1 not recent" do
    setup do
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:questionnaire, created_at: 3.week.ago, user: user, last_editor: user)
      FactoryGirl.create(:questionnaire, user: user, last_editor: user)
      FactoryGirl.create(:questionnaire, user: user, last_editor: user)
    end

    should "return 3 questionnaires when find :all is called" do
      assert_equal 3, Questionnaire.all.size
    end
  end

  context "Testing the cloning method of Questionnaire. Which creates a clone of that questionnaire. Starting with a section. " do
    setup do
      user = FactoryGirl.create(:user)
      @questionnaire = FactoryGirl.create(:questionnaire, user: user, last_editor: user)
      #add a questionnaire field
      FactoryGirl.create(:questionnaire_field, questionnaire: @questionnaire)
      #Add Sections
      qpart_s = FactoryGirl.create(:questionnaire_part, :part => FactoryGirl.create(:section))
      FactoryGirl.create(:section_field, section: qpart_s.part)
      @questionnaire.questionnaire_parts << qpart_s

      CloneQuestionnaire.perform_async(FactoryGirl.create(:user).id,
                                         @questionnaire.id,
                                         "http://www.example.com",
                                         false)
      @copy = @questionnaire.copies.first
    end
    should "@copy have it's source set to @questionnaire" do
      assert_equal @questionnaire.id, @copy.original_id
    end

    should "@questionnaire have 1 copy" do
      assert_equal @questionnaire.copies.size, 1
    end
    should "have the same number of sections as the original." do
      assert_equal @questionnaire.sections.size, @copy.sections.size
    end
    context "Adding a question to that section and cloning again. " do
      setup do
        qp_section = @questionnaire.questionnaire_parts.first
        text_answer = FactoryGirl.create(:text_answer, :answer_type_fields_attributes => {0 => {is_default_language: true, language: 'en'}})
        qp_question = FactoryGirl.create(
          :questionnaire_part,
          part: FactoryGirl.create(:question, :answer_type => text_answer, section: qp_section.part)
        )
        FactoryGirl.create(:question_field, question: qp_question.part)
        qp_question.move_to_child_of(qp_section)
        CloneQuestionnaire.perform_async(FactoryGirl.create(:user).id,
                                           @questionnaire.id,
                                           "http://www.example.com",
                                           false)
        @copy = @questionnaire.copies.
          find(:all, :order => "id DESC").first
      end
      should "@questionnaire have 2 copies" do
        assert_equal @questionnaire.copies.size, 2
      end
      should "have one question associated with its only section." do
        assert_equal 1, @copy.sections.size
        assert_equal 1, @copy.sections.first.questions.size
      end
      context "Having a loop source associated with the @questionnaire. " do
        setup do
          @loop_source = FactoryGirl.create(:loop_source, questionnaire: @questionnaire)
          FactoryGirl.create(:source_file, loop_source: @loop_source)
          @loop_item_type = FactoryGirl.create(:loop_item_type, :name => 'LIT 1', :loop_source_id => @loop_source.id)
          extra = FactoryGirl.create(:extra, loop_item_type: @loop_item_type)
          @loop_item_type2 = FactoryGirl.create(:loop_item_type, :name => 'LIT 2', :parent_id => @loop_item_type.id)
          (1..2).each do
            loop_item_name = FactoryGirl.create(
              :loop_item_name,
              :loop_item_type_id => @loop_item_type.id,
              :loop_source_id => @loop_source.id
            )
            FactoryGirl.create(:item_extra, loop_item_name: loop_item_name, extra: extra)
            loop_item = FactoryGirl.create(
              :loop_item,
              :loop_item_name_id => loop_item_name.id,
              :loop_item_type_id => @loop_item_type.id
            )
            loop_item_name2 = FactoryGirl.create(
              :loop_item_name,
              :loop_item_type_id => @loop_item_type2.id,
              :loop_source_id => @loop_source.id
            )
            loop_item2 = FactoryGirl.create(
              :loop_item,
              :loop_item_name_id => loop_item_name2.id,
              :loop_item_type_id => @loop_item_type2.id,
              :parent_id => loop_item.id)
          end
          @questionnaire.loop_sources << @loop_source
          CloneQuestionnaire.perform_async(FactoryGirl.create(:user).id,
                                             @questionnaire.id,
                                             "http://www.example.com",
                                             false)
          @copy = @questionnaire.copies.
            find(:all, :order => "id DESC").first
        end
        should "have the same number of loop sources as the original." do
          assert_equal @questionnaire.loop_sources.size, @copy.loop_sources.size
        end
        should "have its loop source with the same name as the original's." do
          assert_equal @loop_source.name, @copy.loop_sources.first.name
        end
        should "have its loop source with a loop item type of the same name as @loop_source, and same number of loop_item_types." do
          assert_equal @loop_item_type.name, @copy.loop_sources.first.loop_item_type.name
          assert_equal @loop_item_type.children.size, @copy.loop_sources.first.loop_item_type.children.size
        end
        should "the @loop_item_type's loop_item have a loop_item_name associted" do
          assert_not_nil @loop_item_type.loop_items.first.loop_item_name
        end
        context "Having a filtering field associated with the @questionnaire, consisting of @loop_item_type. " do
          setup do
            @filtering_field = FactoryGirl.create(:filtering_field, questionnaire: @questionnaire)
            @questionnaire.filtering_fields << @filtering_field
            @loop_item_type.filtering_field = @filtering_field
            @loop_item_type.save
            CloneQuestionnaire.perform_async(FactoryGirl.create(:user).id,
                                               @questionnaire.id,
                                               "http://www.example.com",
                                               false)
            @copy = @questionnaire.copies.
              find(:all, :order => "id DESC").first
          end
          should "have a filtering field associated" do
            assert_not_nil @copy.filtering_fields.first
          end
          should "have a filtering field associated with the same name as @filtering_field." do
            assert_equal @filtering_field.name, @copy.filtering_fields.first.name
          end
          should "have its associated filtering_field associated with a loop_item_type of the same name of @loop_item_type" do
            assert_equal @filtering_field.loop_item_types.first.name, @copy.filtering_fields.first.loop_item_types.first.name
          end
          should "have the loop_item_type associated with the filtering_field with the same number of loop_items and those with the same loop_item name as the original @questionnaire" do
            assert_equal @loop_item_type.loop_items.size, @copy.filtering_fields.first.loop_item_types.first.loop_items.size
            assert_equal @loop_item_type.loop_items.first.loop_item_name.item_name, @copy.filtering_fields.first.loop_item_types.first.loop_items.first.loop_item_name.item_name
          end
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: questionnaires
#
#  id                       :integer          not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  last_edited              :datetime
#  user_id                  :integer          not null
#  last_editor_id           :integer
#  activated_at             :datetime
#  administrator_remarks    :text
#  questionnaire_date       :date
#  header_file_name         :string(255)
#  header_content_type      :string(255)
#  header_file_size         :integer
#  header_updated_at        :datetime
#  status                   :integer          default(0)
#  display_in_tab_max_level :string(255)      default("3")
#  delegation_enabled       :boolean          default(TRUE)
#  help_pages               :string(255)
#  translator_visible       :boolean          default(FALSE)
#  private_documents        :boolean          default(TRUE)
#  original_id              :integer
#
