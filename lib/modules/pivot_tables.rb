module PivotTables
  FILE_NAME_PREFIX = 'RAMSAR_Report_'

  def self.available_for_download?(questionnaire)
    last_generated_file_path(questionnaire).present?
  end

  def self.dir_path(questionnaire)
    "#{Rails.root}/private/questionnaires/#{questionnaire.id}/"
  end

  def self.last_generated_file_path(questionnaire)
    glob_expr = "#{dir_path(questionnaire)}/#{FILE_NAME_PREFIX}*.xls"
    Dir[glob_expr].max_by{ |f| File.mtime(f) }
  end

  def self.last_generated_on(questionnaire)
    File.mtime(
      last_generated_file_path(questionnaire)
    )
  end

  class Generator

    def initialize(questionnaire)
      @questionnaire = questionnaire
      @dir_path = PivotTables.dir_path(questionnaire)
      @section_3_questions = section_3_questions_rel
      @respondents = User.
        select([:user_id, :country, :region, :status]).
        from('api_respondents_view users').
        where(status: 'Submitted', questionnaire_id: @questionnaire.id)
      @goals = ['Goal 1', 'Goal 2', 'Goal 3', 'Goal 4']
      initialize_expanded_headers
    end

    def initialize_expanded_headers
      @expanded_headers_index = Hash[@goals.map { |g| [g, []] }]
      questions = @section_3_questions

      questions_with_looping_identifiers = {}
      questions.each do |q|
        looping_section = q.section.self_and_ancestors.select{ |s| s.looping? }.first
        if looping_section.present?
          questions_with_looping_identifiers[q.id] = looping_section.build_all_looping_identifiers
        end
      end

      questions_with_matrix_queries = {}
      matrix_answer_questions_rel(questions).each do |q|
        questions_with_matrix_queries[q.id] = q.answer_type.matrix_answer_queries.includes(:matrix_answer_query_fields).where('matrix_answer_query_fields.is_default_language' => true)
      end

      @numeric_question_ids = numeric_answer_answers_rel(questions).uniq(:question_id).pluck(:question_id).map(&:to_i)

      @headers_with_looping_contexts = []
      @identifiers_with_looping_contexts = []

      questions.each do |q|
        header_segments, identifier_segments = [[q.uidentifier]], [[q.id]]
        matrix_queries = questions_with_matrix_queries[q.id]
        matrix_header_segments, matrix_identifier_segments = if matrix_queries.present?
          [
            matrix_queries.map { |mq| matrix_query_identifier_as_text(mq.id, 'en') },
            matrix_queries.map { |mq| mq.id }
          ]
        elsif @numeric_question_ids.include?(q.id)
          [
            [nil, 'val'],
            [nil, 'val']
          ]
        else
          [
            [nil],
            [nil]
          ]
        end
        header_segments = header_segments.product(matrix_header_segments)
        identifier_segments = identifier_segments.product(matrix_identifier_segments)
        looping_identifiers = questions_with_looping_identifiers[q.id]
        looping_header_segments, looping_identifier_segments = if looping_identifiers.present?
          [
            looping_identifiers.map { |li| looping_identifier_as_text(li, 'en') },
            identifier_segments.product(looping_identifiers)
          ]
        else
          [
            [nil],
            [nil]
          ]
        end
        header_segments = header_segments.product(looping_header_segments)
        identifier_segments = identifier_segments.product(looping_identifier_segments)

        header_segments.each do |hs|
          @headers_with_looping_contexts << hs.flatten.compact.join(' | ')
          @expanded_headers_index[q.goal] << @headers_with_looping_contexts.length - 1
        end
        identifier_segments.each do |is|
          @identifiers_with_looping_contexts << is.flatten
        end
      end
      
      puts @expanded_headers_index.inspect

      @number_of_data_columns = 3 + @headers_with_looping_contexts.size
      @number_of_data_rows = @respondents.size + 1
    end

    def run
      if !File.directory? @dir_path
        FileUtils.mkdir_p(@dir_path)
      end
      Rails.logger.debug("#{Time.now} Started generating pivot tables")
      elapsed_time = Benchmark.realtime do

        Axlsx::Package.new do |p|
          data = create_data_sheet(p.workbook)
          @goals.each do |goal|
            create_pivot_tables_sheet(p.workbook, goal, data)
          end
          p.serialize(new_file_path(@questionnaire))
        end
      end
      Rails.logger.debug("#{Time.now} Finished generating pivot tables in #{elapsed_time}s")
    end

    def new_file_name(questionnaire)
      "#{FILE_NAME_PREFIX}#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.xls"
    end

    def new_file_path(questionnaire)
      [
        @dir_path,
        new_file_name(questionnaire)
      ].join('/')
    end

    def looping_identifier_as_text(looping_identifier, lng)
      looping_identifier.split(LoopItem::LOOPING_ID_SEPARATOR).map do |li_id|
        li = LoopItem.find_by_id(li_id).try(:loop_item_name).try(:item_name, lng)
      end
    end

    def matrix_query_identifier_as_text(matrix_answer_query_id, lng)
      maq = MatrixAnswerQuery.find(matrix_answer_query_id)
      return '?' unless maq
      maq_f = maq.matrix_answer_query_fields.where(language: lng).first
      return '?' unless maq_f
      maq_f.title.split[0]
    end

    def create_data_sheet(workbook)
      workbook.add_worksheet(name: 'Data') do |sheet|
        sheet.add_row ['REGION_Ramsar2', 'REGION_Ramsar', 'CNTRY_Ramsar'] + @headers_with_looping_contexts,
          types: Array.new(@number_of_data_columns){:string}
        @respondents.each do |respondent|
          sheet.add_row data_row_for_respondent(@section_3_questions, respondent, @identifiers_with_looping_contexts)
        end
      end
    end

    def create_pivot_tables_sheet(workbook, goal, data_sheet)
      # select subset of columns from the data sheet that relate to this goal
      headers_with_looping_contexts = @headers_with_looping_contexts.values_at(*@expanded_headers_index[goal])
      identifiers_with_looping_contexts = @identifiers_with_looping_contexts.values_at(*@expanded_headers_index[goal])
      workbook.add_worksheet(name: goal) do |sheet|
        current_row = 1
        data_range = "A1:#{column_index(@number_of_data_columns -1)}#{@number_of_data_rows}"
        numeric_option_header = nil
        headers_with_looping_contexts.each_with_index do |h, idx|
          is_numeric = @numeric_question_ids.include?(identifiers_with_looping_contexts[idx].first)
          if is_numeric && numeric_option_header.nil?
            numeric_option_header = h
            # if this is the "option code" numeric column, save its header
            # and skip to next iteration to process it with the value column
            next
          end

          table_range = "A#{current_row}:G#{current_row + 12}"
          rows = ['REGION_Ramsar2', 'REGION_Ramsar']
          columns = if is_numeric
            [numeric_option_header]
          else
            [h]
          end
          data = if is_numeric
            [{ref: h, subtotal: 'sum'}]
          else
            [{ref: h, subtotal: 'count'}]
          end

          sheet.add_pivot_table(table_range, data_range) do |pivot_table|
            pivot_table.data_sheet = data_sheet
            pivot_table.rows = rows
            pivot_table.columns = columns
            pivot_table.data = data
          end
          numeric_option_header = nil if is_numeric
          current_row += 13
        end
      end
    end
    
    # identifiers_with_looping_contexts is an array of arrays like so:
    # [question identifier, matrix query identifier, looping identifier]
    # both matrix query identifier and looping identifier may be nil
    # e.g. [['19.4', nil], ['19.5', '216S218']]
    # the question identifier comes from questions.id column
    # the looping identifier comes from answers.looping_identifier column
    # the looping identifier is constructed from loop item ids joined using a looping separator ('S')
    def data_row_for_respondent(questions_rel, respondent, identifiers_with_looping_contexts)
      index_hash = Hash[identifiers_with_looping_contexts.each_with_index.map { |x, i| [x, i] }]
      result = Array.new(identifiers_with_looping_contexts.size)

      multi_answers = multi_answer_answers_rel(questions_rel).where(user_id: respondent.user_id)
      multi_answers.each do |ma|
        result[index_hash[[ma.question_id.to_i, nil, ma.looping_identifier]]] = ma.option_code
      end

      numeric_answers = numeric_answer_answers_rel(questions_rel).where(user_id: respondent.user_id)
      numeric_answers.each do |na|
        result[index_hash[[na.question_id.to_i, nil, na.looping_identifier]]] = na.option_code
        result[index_hash[[na.question_id.to_i, 'val', na.looping_identifier]]] = na.details_text
      end

      matrix_answers = matrix_answer_answers_rel(questions_rel).where(user_id: respondent.user_id)
      matrix_answers.each do |ma|
        result[index_hash[[ma.question_id.to_i, ma.matrix_answer_query_id.to_i, ma.looping_identifier]]] = ma.option_code
      end
      region2 = if respondent.region == 'Asia' || respondent.region == 'Oceania'
        'Asia/Oceania'
      elsif respondent.region == 'North America' || respondent.region == 'Latin America and the Caribbean'
        'Americas'
      else
        respondent.region
      end
      [region2, respondent.region, respondent.country] + result
    end

    def column_index(column_number)
      index_hash = Hash.new {|hash,key| hash[key] = hash[key - 1].next }.merge({0 => "A"})
      index_hash[column_number]
    end

    private

    def section_3_questions_rel
      Question.
        from('pt_questions_view questions').
        where(
          questionnaire_id: @questionnaire.id,
          root_section: 'Section 3',
          answer_type_type: ['MultiAnswer', 'MatrixAnswer']
        ).
        order(:lft)
    end

    def matrix_answer_questions_rel(questions_rel)
      questions_rel.where(answer_type_type: 'MatrixAnswer')
    end

    def multi_answer_answers_rel(questions_rel)
      MultiAnswer.
        from('pt_multi_answer_answers_by_user_view multi_answers').joins(
          'JOIN (' + questions_rel.to_sql + ') questions' +
          " ON multi_answers.question_id = questions.id AND questions.answer_type_type = 'MultiAnswer'"
        ).
        where('NOT details_field') # this to exclude the "exact" etc pseudo-numeric questions
    end

    def numeric_answer_answers_rel(questions_rel)
      MultiAnswer.
        from('pt_multi_answer_answers_by_user_view multi_answers').joins(
          'JOIN (' + questions_rel.to_sql + ') questions' +
          " ON multi_answers.question_id = questions.id AND questions.answer_type_type = 'MultiAnswer'"
        ).
        where('details_field') # this to include only the "exact" etc pseudo-numeric questions
    end

    def matrix_answer_answers_rel(questions_rel)
      MatrixAnswer.
        from('pt_matrix_answer_answers_by_user_view matrix_answers').joins(
          'JOIN (' + questions_rel.to_sql + ') questions' +
          " ON matrix_answers.question_id = questions.id AND questions.answer_type_type = 'MatrixAnswer'"
        )
    end

  end
end
