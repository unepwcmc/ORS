module SectionsAndQuestionsShared

  def self.append_features(base)
    super
    self.class_eval do

      def questionnaire
        self.questionnaire_part.root.questionnaire
      end

      def title lang=nil
        field = lang ? self.send(self.class.to_s.underscore.downcase+"_fields").find_by_language(lang) : nil
        the_title = field ? field.title : self.send(self.class.to_s.underscore.downcase+"_fields").find_by_is_default_language(true).title
        the_title ? the_title : "#Not Specified#"
      end

      def description
        self.send(self.class.to_s.underscore.downcase+"_fields").find_by_is_default_language(true).description
      end

      private
      def destroy_answer_type
        return true unless self.answer_type
        #return true without deleting the answer type if the answer_type is associated
        #with other objects (be it questions or sections)
        return true if self.is_a?(Question) &&
          (self.answer_type.questions.count > 1 || self.answer_type.sections.count > 0)
        if self.answer_type_type.present? && self.answer_type_id.present? && self.answer_type
          self.answer_type.destroy
        else
          true
        end
      end
    end
  end
end
