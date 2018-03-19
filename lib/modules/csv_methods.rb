class CsvMethods

  def self.fill_csv file_location, submitters, sections, separator
    puts "Generating CSV file"
    puts "Opened file: #{file_location}"
    CSV.open(file_location, "w", {:col_sep => separator}) do |csv|
      #first row has the id's of the users that are authorized to fill a questionnaire.
      sorted_submitters = submitters.sort { |a,b| a.first_name <=> b.first_name }
      submitters_ids = sorted_submitters.map(&:id)
      submitters_head_line = sorted_submitters.map(&:full_name)
      csv << ["Section", "Question", "ID"] + submitters_head_line

      #Add submitters info as rows at the top of the file
      #Skip two columns as those are related to the Question title and uidentifer columns
      #Skip extra column related to answer details
      csv << ["Region", '', ''] + sorted_submitters.map(&:region)
      csv << ["Country", '', ''] + sorted_submitters.map(&:country)
      csv << ["e-mail", '', ''] + sorted_submitters.map(&:email)

      Array(sections).each do |section|
        loop_sources = {}
        if section.looping? && !section.loop_item_type.filtering_field_id.present?
          #item_names = section.loop_item_type.loop_item_names
          loop_items = section.loop_item_type.loop_items
          loop_items.each do |item|
            loop_sources[section.loop_item_type.root.loop_source.id.to_s] = item
            CsvMethods.export(csv, section, submitters_ids, loop_sources, item, item.id.to_s)#item.id.to_s => initial looping_identifier
          end
        else
          CsvMethods.export(csv, section, submitters_ids, loop_sources, nil)
        end
      end
    end
    puts "CSV finished generating (#{file_location})"
    true
  end

  def self.export csv, the_section, submitters_ids, loop_sources, loop_item=nil, looping_identifier=nil
    #puts "Dealing with section #{the_section.id} for item: #{item.try(:item_name)}"
    if !loop_item || (loop_item && !loop_item.loop_item_type.filtering_field_id)
      if !the_section.is_hidden? && !the_section.questions.any?
        next_row = Array.new(submitters_ids.size + 3)
        if loop_item
          next_row[0] = "." + "--"*the_section.level + OrtSanitize.white_space_cleanse(the_section.section_fields.find_by_is_default_language(true).loop_title(nil, loop_item))
        else
          next_row[0] = "." + "--"*the_section.level + OrtSanitize.white_space_cleanse(the_section.title)
        end
        if the_section.depends_on_option
          next_row[0] += " - This section depends on the option #{the_section.depends_on_option.multi_answer_option_fields.find_by_is_default_language(true).option_text}
                         being #{the_section.depends_on_option_value? ? "selected" : "not selected"}, for question #{the_section.depends_on_question.title} of #{the_section.depends_on_question.section.title}"
        end
        csv << next_row
      end
    end
    the_section.questions.order(:uidentifier).each do |q|
      q.to_csv(csv, submitters_ids, loop_sources, loop_item, looping_identifier)
    end
    the_section.children.each do |s|
      if s.looping?
        #item_names = s.loop_item_type.loop_item_names
        items = s.next_loop_items loop_item, loop_sources
        items.each do |item|
          loop_sources[s.loop_item_type.root.loop_source.id.to_s] = item
          new_looping_identifier = looping_identifier ? "#{looping_identifier}#{LoopItem::LOOPING_ID_SEPARATOR}#{item.id}" : item.id.to_s
          CsvMethods.export(csv, s, submitters_ids, loop_sources, item, new_looping_identifier)
        end
      else
        CsvMethods.export csv, s, submitters_ids, loop_sources, loop_item, looping_identifier
      end
    end
  end

  def self.answers_to_csv s_title, q_title, q_identifier, submitters_ids, answers
    row = Array.new(submitters_ids.size + 3)
    row[0] = s_title
    row[1] = q_title
    row[2] = q_identifier
    details_row = []
    submitters_ids.each_with_index do |val, i|
      answer = answers[val.to_s]
      if answer
        answer_text = []
        answer_details = ''
        answer.answer_parts.each do |ap|
          if ap.field_type_type.present? && ["MultiAnswerOption", "RangeAnswerOption"].include?(ap.field_type_type)
            answer_text << ap.field_type.try(:option_text)
            if ap.field_type_type == "MultiAnswerOption" && ap.field_type && ap.field_type.details_field
              details_row[0] = s_title
              details_row[1] = "#{q_title} #Text"
              details_row[2] = "#{q_identifier} #Text"
              details_row[i+3] = ap.details_text
            end
            #answer_text << ap.details_text if ap.field_type_type == "MultiAnswerOption"
          else
            answer_text << (ap.answer_text_in_english.present? ? "en: #{ap.answer_text_in_english} ||\n ol: ": "") + "#{ap.try(:answer_text)||""}"
          end
        end
        if answer.other_text.present?
          answer_text << "Other:#{ answers[val.to_s].other_text}"
        end
        answer.answer_links.each do |link|
          answer_text << "URL: #{link.url}"
        end
        answer.documents.each do |document|
          answer_text << "Doc: #{document.doc.url.split('?')[0]}"
        end
        timestamp = " [[timestamp: #{answer.updated_at}]]"
        row[i+3] = answer_text.join(" # ") << timestamp
      end
    end
    details_row.empty? ? row : [row, details_row]
  end
end
