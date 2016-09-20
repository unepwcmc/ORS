module SectionBranchMethods

  ###
  ###     Methods that traverse a section's branch on the questionnaire tree.
  ###

  def self.append_features(base)
    super
    self.class_eval do

      #count self and descendants questions that are available for a user
      def count_self_and_descendants_questions user, info_holder
        loop_sources_items = {}
        if self.looping?
          loop_items = self.loop_item_type.loop_items
          loop_items.each do |loop_item|
            if self.available_for? user, loop_item
              loop_sources_items[self.loop_source.id.to_s] = loop_item
              self.count_descendants_questions user, loop_item, loop_sources_items, info_holder
            end
          end
        else
          self.count_descendants_questions user, nil, loop_sources_items, info_holder
        end
      end

      #go through the descendants, and through the loop items available for a user.
      def count_descendants_questions user, loop_item, loop_sources_items, info_holder
        info_holder[:available_questions] += self.questions.size
        self.children.each do |child|
          if !child.depends_on_question.present?
            #if children is of looping type
            if child.looping?
              #get the items through which it is going to loop on
              items = child.next_loop_items loop_item, loop_sources_items
              #for each of the items"
              items.each do |item|
                #check if the section is available for the user
                if child.available_for? user, item
                  #update the loop_sources history.
                  loop_sources_items[child.loop_source.id.to_s] = item
                  #call the function for the children, sending the necessary items.
                  child.count_descendants_questions user, item, loop_sources_items, info_holder
                end
              end
            else
              #if it is not a looping item just call the function and send the same items...
              child.count_descendants_questions user, loop_item, loop_sources_items, info_holder
            end
          end
        end
      end

      #delete children sections and questions
      def delete_branch_questions!
#        self.children.each do |child|
#          child.delete_branch_questions!
#        end
#        self.questions.each do |q|
#          q.answer_type.destroy if q.answer_type.present?
#          q.questionnaire_part.destroy
#          q.destroy
#        end
        self.questionnaire_part.destroy_branch
        #self.destroy
      end

      def section_and_descendants_answers_for user
        Answer.find(:all, :joins => :question, :conditions => {"questions.section_id" => self.self_and_descendants.map{ |a| a.id }, "answers.user_id" => user.id}, :include => [:last_editor, :documents, :answer_links, :user])
      end

      def has_looping_descendants?
        self.looping_descendants.any?
      end

      def looping_descendants
        ids = self.questionnaire_part.descendants.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(:all, :conditions => {:id => ids.map{ |p| p.part_id }, :section_type => SectionType::LOOPING}, :include => :questionnaire_part)
      end

      def has_dependent_descendants?
        self.dependent_descendants.any?
      end

      def dependent_descendants
        ids = self.questionnaire_part.descendants.find(:all, :conditions => {:part_type => "#{self.class}"}, :select => 'part_id')
        self.class.find(:all, :conditions => {:id => ids.map{ |p| p.part_id }, :depends_on_question_id => nil}, :include => :questionnaire_part)
      end
    end
  end
end
