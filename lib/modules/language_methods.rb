module LanguageMethods

  def self.language_code title
    case title
      when "Arabic"
        "ar"
      when "Chinese"
        "zh"
      when "English"
        "en"
      when "French"
        "fr"
      when "Spain"
        "es"
      when "Russian"
        "ru"
    end
  end

  def self.append_features(base)
    super

    self.class_eval do
      def language_full_name
        case self.language
          when "ar"
            "العربية"
          when "zh"
            "简体字"
          when "en"
            "English"
          when "fr"
            "Français"
          when "ru"
            "русский язык"
          when "es"
            "Español"
          else
            self.language
        end
      end

      def language_english_name
        case self.language
          when "ar"
            "Arabic"
          when "zh"
            "Chinese"
          when "en"
            "English"
          when "fr"
            "French"
          when "ru"
            "Russian"
          when "es"
            "Spanish"
          else
            self.language
        end
      end

      def propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
        fields_name = []
        if [NumericAnswer, TextAnswer, RankAnswer, MatrixAnswer, RangeAnswer].include?(self.class)
          fields_name << "answer_type_fields"
        elsif self.is_a?(MultiAnswer)
          fields_name << "answer_type_fields"
          if !self.other_fields.empty?
            fields_name << "other_fields"
          end
        else
          fields_name << self.class.to_s.underscore.downcase+"_fields"
        end
        langs_to_remove.each do |to_remove|
          fields_name.each do |field_name|
            field = self.send(field_name).find_by_language(to_remove)
            field.destroy if field.present?
          end
        end
        langs_to_add.each do |to_add|
          fields_name.each do |field_name|
            if !self.send(field_name).find_by_language(to_add)
              self.send(field_name).create(:language => to_add)
            end
          end
        end
        if new_default
          fields_name.each do |field_name|
            old_default = self.send(field_name).find_by_is_default_language(true)
            if old_default
              old_default.is_default_language = false
              old_default.save!
            end
            new_default_field = self.send(field_name).find_by_language(new_default)
            new_default_field.is_default_language = true
            new_default_field.save!
          end
        end
        #call the function for the objects that possess language fields, and are related to self.
        if [Section, Question].include?(self.class)
          if ( self.answer_type_type.present? && self.answer_type_id.present? )
            self.answer_type.propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
          end
        elsif self.is_a?(MultiAnswer) || self.is_a?(RankAnswer) || self.is_a?(RangeAnswer)
          self.send(self.class.to_s.underscore.downcase+"_options").each do |mao|
            mao.propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
          end
        elsif self.is_a?(MatrixAnswer)
          self.matrix_answer_queries.each do |mrow|
            mrow.propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
          end
          self.matrix_answer_options.each do |mcol|
            mcol.propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
          end
          self.matrix_answer_drop_options.each do |mcol|
            mcol.propagate_languages_changes(langs_to_remove, langs_to_add, new_default)
          end
        end
      end

      def value_in value, language, loop_item=nil
        #classes where the *_fields class doesn't have the name of the original class in it
        fields = if [NumericAnswer,TextAnswer, MultiAnswer, RankAnswer, MatrixAnswer, RangeAnswer].include?(self.class)
          self.answer_type_fields
        else #all other classes
          self.send(self.class.to_s.underscore.downcase+"_fields")
        end
        # get the field by language
        field = fields.find{ |f| f.language == language }
        #if the field exists and the value is present send that, otherwise send the default
        field ||= fields.find{ |f| f.is_default_language }
        result = field && field.send(value.to_s)
        if loop_item
          if self.is_a?(Question)
            self.loop_item_types.each do |item_type|
              item = loop_item.self_and_ancestors.find_by_loop_item_type_id(item_type.id)
              if item
                new_result = result.gsub("#[#{item_type.name}]", item.loop_item_name.item_name(language))
                result = new_result.present? ? new_result : result
              end
            end
          else
            return result unless self.loop_item_type
            new_result = result.gsub("#[#{self.loop_item_type.name}]", loop_item.loop_item_name.item_name(language))
            result = new_result.present? ? new_result : result
          end
        end
        result || 'No translation found'
      end

      def loop_title loop_sources, loop_item=nil
        return self.title if not loop_item
        #Sanitize the difference occurrences of loop_item_type variables in the title
        #using a loop in case there are multiple variables in the same title
        result = self.title
        vars = result.gsub(/#\[[^\]]*\]/) #look for occurrences of #[SomeVar]
        vars.each do |match|
          result = result.gsub(match, Sanitize.clean(match))
        end
        #result = self.title.gsub(/#\[[^\]]*\]/,Sanitize.clean(self.title.match(/#\[[^\]]*\]/)[0]))
        if self.is_a?(QuestionField)
          self.question.loop_item_types.each do |item_type|
            item = item_type.root.loop_source_id.present? ?  loop_sources[item_type.root.loop_source.id.to_s] : nil
            if item
              item_to_use = item.loop_item_type == item_type ? item : item.ancestors.find_by_loop_item_type_id(item_type.id)
              new_result = result.gsub("#[#{Sanitize.clean(item_type.name)}]", item_to_use.item_name(self.language))
              result = new_result.present? ? new_result : result
            end
          end
        elsif self.is_a?(SectionField)
          section = self.section
          return result unless section.loop_item_type
          new_result = result.gsub("#[#{Sanitize.clean(section.loop_item_type.name)}]", loop_item.item_name(self.language))
          result = new_result.present? ? new_result : result
        end
        result
      end

      #TODO: add check to see if type of field exists.
      def replace_variables type_of_field, language, loop_sources, loop_item=nil, images_urls=nil
        return self.send(type_of_field.to_s) if !loop_item
        #Sanitize the difference occurrences of variables in the field
        #using a loop in case there are multiple variables in the same field
        result = self.send(type_of_field.to_s)
        vars = result.gsub(/#\[[^\]]*\]/) #look for occurrences of #[SomeVar]
        vars.each do |match|
          result = result.gsub(match, Sanitize.clean(match))
        end
        if self.is_a?(QuestionField)
          obj_type_var = "question"
        else
          obj_type_var = "section"
        end
        self.send(obj_type_var).send("extras").each do |extra|
          item = extra.loop_item_type.root.loop_source_id.present? ? loop_sources[extra.loop_item_type.root.loop_source.id.to_s] : nil
          if item
            item_to_use = item.loop_item_type == extra.loop_item_type ? item.loop_item_name : item.ancestors.find_by_loop_item_type_id(extra.loop_item_type_id).loop_item_name
            the_item_extra = item_to_use.item_extras.find_by_extra_id(extra.id)
            if the_item_extra
              #either in language, or the default, or the first...
              the_field = ( the_item_extra.item_extra_fields.find_by_language(language) || the_item_extra.item_extra_fields.find_by_is_default_language(true) || the_item_extra.item_extra_fields.first)
              if extra.image? #Image
                the_value = "<img src='#{the_field.value}' alt='#{extra.name}::#{item_to_use.item_name(language)}' width='200px'/>"
                unless images_urls.nil?
                  images_urls << the_field.value
                end
              elsif extra.link? #URL
                the_value = "<a href='#{the_field.value}' alt='#{extra.name}::#{item_to_use.item_name(language)}'>#{item_to_use.item_name(language)}</a>"
              else
                the_value = the_field.value #TEXT
              end
              new_result = result.gsub("#[#{Sanitize.clean(extra.loop_item_type.name)}::#{Sanitize.clean(extra.name)}]", the_value)
            else
              new_result = result.gsub("#[#{Sanitize.clean(extra.loop_item_type.name)}::#{Sanitize.clean(extra.name)}]", "")
            end
            result = new_result.present? ? new_result : result
          end
        end
        result
      end
    end
  end
end
