module QuestionsHelper

  def available_loop_types section
    types = []
    section.self_and_ancestors.each do |s|
      if s.loop_item_type
        types += [ s.loop_item_type ]
      end
    end
    types
  end

  def get_matrix_answer_query_results answer_part
    answer_results = {}
    answer_part.answer_part_matrix_options.each do |o|
      answer = "x" # Assumes the answer is nil and from a checkbox
      if o.matrix_answer_drop_option
        answer = o.matrix_answer_drop_option.option_text
      elsif o.answer_text
        answer = o.answer_text
      end
      option = o.matrix_answer_option.title
      answer_results[option] = answer
    end
    answer_results.map{ |k,v| "#{k}=[#{v}]" }.join('&')
  end

end
