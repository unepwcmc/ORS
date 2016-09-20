module AnswerTypeMethods

  def self.append_features(base)
    super

    self.class_eval do

      base.validate :validate_default_language_set

      def validate_default_language_set
        if  self.answer_type_fields.select{ |a| a.is_default_language }.length == 0
          self.errors.add(:answer_type_fields, "Must define a default language")
          return false
        end
        true
      end

      def help_text
        # TODO: possible bug here, this call can fail with:
        # *** NoMethodError Exception: undefined method `help_text' for nil:NilClass
        self.answer_type_fields.find_by_is_default_language(true).help_text
      end

    end
  end
end
