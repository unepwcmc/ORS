module SectionDependencies

  def self.append_features(base)
    super

    self.class_eval do

      #check if the section/generated_section dependency is met (If the current_user's answers include the necessary answers for the
      #section to be visible!
      def dependency_condition_met?(user, looping_identifier=nil)
        #A Question can correspond to more than one generated question
        # so it is necessary to check if the condition is met for all the generated_questions' answers
        question = self.depends_on_question
        user_answers = user.answers.find(:all, :conditions => {:question_id => question.id, :looping_identifier => looping_identifier}, :include => [:answer_parts])
        return false if !user_answers.any?
        user_answers.each do |answer|
          #if not answer.loop_item.present? or question.section.available_for?(user, answer.loop_item)
          if self.depends_on_option_value?
            if !answer.answer_parts.find_by_field_type_id(self.depends_on_option_id)
              return false
            end
          else
            #if the option is present then the condition is not met, when the depends_on_option_value is false!
            if answer.answer_parts.find_by_field_type_id(self.depends_on_option_id)
              return false
            end
          end
          #end
        end
        return true
      end

     # Method to fetch the questions that belong to the argument 'section' and that are
     # available for 'self' to depend on. Only questions with AnswerType of MultyAnswer should be returned
     # @param [Section] section The section from which to get the available questions.
     # @return [Array] Returns an array with the available questions
     def available_questions_for_dependency_from section
       return [] if self == section || self.is_ancestor_of?(section)
       return [] if section.looping? && !self.is_descendant_of?(section)
       section.questions.find(:all, :conditions => {:answer_type_type => "MultiAnswer"})
     end

      # return the section that/if self depends on, based on the depends_on_question value
      def section_that_this_depends_on
        self.depends_on_question ? self.depends_on_question.section.id : nil #""
      end
    end
  end
end
