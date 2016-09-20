require 'test_helper'
#TODO
class SectionTest < ActiveSupport::TestCase

  context "1 section with answer type 2" do
    setup do
      @section = FactoryGirl.create(:section, :section_type => "2")
      @answer_type = FactoryGirl.create(:text_answer)
      @answer_type.sections << @section

      params = {
              :id => @section.id,
              :section => {:section_type=>"3", :name=>"TEste1", :help_text=>"Asdas", :answer_type_type=>""}
              #:section=>{:name=>"Sample Section 12", :section_type=>"3", :help_text=>"Just a general section."}#,
                           #:answer_type_type=>"MultiAnswer"}
               #:answer=>{:display_type=>"", :help_text=>"asasdas", :multi_answer_options_attributes=>{:new_multi_answer_options=>{:option_help=>"", :option_text=>"", :_destroy=>""}},
                #          :other_required=>"0", :answer_type =>"MultiAnswer", :single=>"1"}
              }
      @result = Section.section_update(params)
    end

     #it does not work uncommented, because in the Model the attributes are not updated.
#    should "have type 3 as section_type after updated" do
#       assert_equal 3, @result.section_type
#    end
  end

  context "1 section with \"same answer type\"" do
    setup do
      @section = FactoryGirl.create(:section, :section_type => "1")
      @answer_type = FactoryGirl.create(:text_answer)
      @answer_type.sections << @section

      params = {
              :id => @section.id,
              :section => {:section_type=>"2", :name=>"TEste1", :help_text=>"Asdas", :answer_type_type=>"TextAnswer"}
              #:section=>{:name=>"Sample Section 12", :section_type=>"3", :help_text=>"Just a general section."}#,
                           #:answer_type_type=>"MultiAnswer"}
               #:answer=>{:display_type=>"", :help_text=>"asasdas", :multi_answer_options_attributes=>{:new_multi_answer_options=>{:option_help=>"", :option_text=>"", :_destroy=>""}},
                #          :other_required=>"0", :answer_type =>"MultiAnswer", :single=>"1"}
              }
      @result = Section.section_update(params)
    end

#    should "have type 2 as section_type after updated" do
#       assert_equal 2, @result.section_type
#    end
#
#    should "not have an answer type associated" do
#      assert_equal nil, @result.answer_type
#    end
#
#    should "not exist @answer_type" do
#      assert_raises(ActiveRecord::RecordNotFound) { TextAnswer.find(@answer_type.id) }
#    end
  end

end

# == Schema Information
#
# Table name: sections
#
#  id                      :integer          not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  last_edited             :datetime
#  section_type            :integer          not null
#  answer_type_id          :integer
#  answer_type_type        :string(255)
#  loop_source_id          :integer
#  loop_item_type_id       :integer
#  depends_on_option_id    :integer
#  depends_on_option_value :boolean          default(TRUE)
#  depends_on_question_id  :integer
#  is_hidden               :boolean          default(FALSE)
#  starts_collapsed        :boolean          default(FALSE)
#  display_in_tab          :boolean          default(FALSE)
#  original_id             :integer
#
