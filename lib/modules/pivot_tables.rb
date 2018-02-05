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
    include ActionView::Helpers::SanitizeHelper

    def initialize(questionnaire)
      @questionnaire = questionnaire
      @dir_path = PivotTables.dir_path(questionnaire)
      @section_3_questions = section_3_questions_rel
      @respondents = User.
        select([:user_id, :country, :region, :status]).
        from('api_respondents_view users').
        where(status: 'Submitted', questionnaire_id: @questionnaire.id)
      @goals = ['Goal 1', 'Goal 2', 'Goal 3', 'Goal 4']
      @numeric_question_ids = numeric_answer_answers_rel(@section_3_questions).
        uniq(:question_id).pluck(:question_id).map(&:to_i)
      initialize_expanded_headers
    end

    # This initialises a number of structures that will be used to populate
    # the Data sheet and the pivot tables.
    def initialize_expanded_headers
      # @expanded_headers is the array of question headers on the Data sheet
      # It's called "expanded", because a single question can generate more
      # than one column. It contains the question uidentifier + some context.
      # For example:
      # - a matrix question with 3 dropdowns will generate 3 columns, e.g. '1.1 | a)', '1.1 | b)', '1.1 | c)'
      # - multiple choice question with numeric details text will generate 2 columns, e.g. '2.6 code', '2.6'
      # - any question within a looping section will generate as many columns as there are possible looping contexts, where the context information is the looping identifier
      @expanded_headers = []
      # For each header we also generate an identifier to reference internally within this script.
      # This is always a 3-element array:
      # 0. question id (not uidentifier)
      # 1. question-type specific info
      # 2. looping identifier
      # 1 & 2 may be nil.
      # The question-type specific info can be:
      # - matrix query id for matrix questions
      # - string 'code' for pseudo-numeric option code column, to differentiate
      # from the value column, which will have this field nil
      # The looping identifier comes from answers.looping_identifier column. It is
      # constructed from loop item ids joined using a looping separator ('S').
      @expanded_headers_identifiers = []

      # This structure will map column indexes from @expanded_headers to goals,
      # so that we know which columns from the Data sheet refer to a goal.
      @expanded_headers_index = Hash[@goals.map { |g| [g, []] }]

      @expanded_titles = []

      @section_3_questions.each do |q|
        # Initially we assume we have just 1 column per question
        header_segments, identifier_segments = [[q.uidentifier]], [[q.id]]

        # Next, we check if this is a matrix question with matrix queries.
        # In such case we'll need as many columns as there are queries.
        matrix_queries = questions_with_matrix_queries[q.id]
        matrix_header_segments, matrix_identifier_segments = if matrix_queries.present?
          [
            matrix_queries.map { |mq| matrix_query_identifier_as_text(mq.id, 'en') },
            matrix_queries.map { |mq| mq.id }
          ]
        # In case it is a numeric question, we'll need a separate column for the
        # option code and a separate one for the numeric value.
        # This has to do with the fact that numeric questions have been structured
        # using multiple choice question with details text to store the numeric value.
        elsif @numeric_question_ids.include?(q.id)
          [
            ['code', nil],
            ['code', nil]
          ]
        # Otherwise we still assume it's just one column.
        else
          [
            [nil],
            [nil]
          ]
        end
        # We use the product function to produce the cartesian product of initial
        # column set and one extablished in last step.
        header_segments = header_segments.product(matrix_header_segments)
        identifier_segments = identifier_segments.product(matrix_identifier_segments)

        # Finaly, we check if we are in a looping section. In such case we'll need
        # as many columns as there are possible looping contexts for this question.
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
        # Use the product function again to arrive at final set of columns for this question
        header_segments = header_segments.product(looping_header_segments)
        identifier_segments = identifier_segments.product(looping_identifier_segments)

        # We store both the header of the column (displayed) and identifier (used in script);
        # they can be linked to each other based on position in the array.
        # We also add that position to the relevant goal's index.
        header_segments.each do |hs|
          @expanded_headers << hs.flatten.compact.join(' | ')
          @expanded_titles << q.title
          @expanded_headers_index[q.goal] << @expanded_headers.length - 1
        end
        identifier_segments.each do |is|
          @expanded_headers_identifiers << is.flatten
        end
      end

      @number_of_data_columns = 3 + @expanded_headers.size
      @number_of_data_rows = @respondents.size + 1
    end

    def run
      if !File.directory? @dir_path
        FileUtils.mkdir_p(@dir_path)
      end
      Rails.logger.debug("#{Time.now} Started generating pivot tables")
      elapsed_time = Benchmark.realtime do

        Axlsx::Package.new do |p|
          # First, generate the data sheet and keep reference -
          # it is needed in the pivot tables sheets.
          data = create_data_sheet(p.workbook)
          # For each goal, generate a pivot tables sheet.
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

    REGIONS = ['Wider Region', 'Region', 'Country']
    def create_data_sheet(workbook)
      workbook.add_worksheet(name: 'Data') do |sheet|
        sheet.add_row REGIONS + @expanded_headers,
          types: Array.new(@number_of_data_columns){:string}
        @respondents.each do |respondent|
          sheet.add_row data_row_for_respondent(@section_3_questions, respondent, @expanded_headers_identifiers)
        end
      end
    end

    ROWS_RANGE = 14
    def create_pivot_tables_sheet(workbook, goal, data_sheet)
      # select subset of columns from the data sheet that relate to this goal
      expanded_headers = @expanded_headers.values_at(*@expanded_headers_index[goal])
      expanded_titles = @expanded_titles.values_at(*@expanded_headers_index[goal])
      expanded_headers_identifiers = @expanded_headers_identifiers.values_at(*@expanded_headers_index[goal])
      section_3_questions = @section_3_questions.to_a
      workbook.add_worksheet(name: goal) do |sheet|
        current_row = 1
        data_range = "A1:#{column_index(@number_of_data_columns -1)}#{@number_of_data_rows}"
        numeric_option_header = nil
        expanded_headers.each_with_index do |h, idx|
          is_numeric = @numeric_question_ids.include?(expanded_headers_identifiers[idx].first)
          if is_numeric && numeric_option_header.nil?
            numeric_option_header = h
            # if this is the "option code" numeric column, save its header
            # and skip to next iteration to process it with the value column
            next
          end

          table_starts = current_row + 2
          table_ends = table_starts + 12
          table_range = "A#{table_starts}:G#{table_ends}"
          rows = REGIONS - ['Country']
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

          #Skip rows occupied by pivot table to insert title
          if idx > 0
            (ROWS_RANGE+1).times do |index|
              Axlsx::Row.new sheet, ['']
            end
          end
          title = HTMLEntities.new.decode(strip_tags(expanded_titles[idx]))
          Axlsx::Row.new sheet, [title]

          sheet.add_pivot_table(table_range, data_range, {no_subtotals_on_headers: ['Wider Region']}) do |pivot_table|
            pivot_table.data_sheet = data_sheet
            pivot_table.rows = rows
            pivot_table.columns = columns
            pivot_table.data = data
          end
          numeric_option_header = nil if is_numeric
          current_row += ROWS_RANGE + 2
        end
      end
    end

    def data_row_for_respondent(questions_rel, respondent, expanded_headers_identifiers)
      index_hash = Hash[expanded_headers_identifiers.each_with_index.map { |x, i| [x, i] }]
      result = Array.new(expanded_headers_identifiers.size)

      multi_answers = multi_answer_answers_rel(questions_rel).where(user_id: respondent.user_id)
      multi_answers.each do |ma|
        idx = index_hash[[ma.question_id.to_i, 'code', ma.looping_identifier]]
        result[idx] = ma.option_code if idx.present?
        if idx.present?
          result[idx] = ma.option_code
          result[index_hash[[ma.question_id.to_i, nil, ma.looping_identifier]]] = ma.details_text
        else
          #TODO The real fix here is just to leave this line in the each block
          # The bug of the multiple answers per user is also causing a bug here
          # having code displayed in the wrong column or both
          # That's probably also because question 2.6 for example has some answers which
          # accept details field and others don't
          result[index_hash[[ma.question_id.to_i, nil, ma.looping_identifier]]] = ma.option_code
        end
      end

      numeric_answers = numeric_answer_answers_rel(questions_rel).where(user_id: respondent.user_id)
      numeric_answers.each do |na|
        result[index_hash[[na.question_id.to_i, 'code', na.looping_identifier]]] = na.option_code
        result[index_hash[[na.question_id.to_i, nil, na.looping_identifier]]] = na.details_text
      end

      matrix_answers = matrix_answer_answers_rel(questions_rel).where(user_id: respondent.user_id)
      matrix_answers.each do |ma|
        result[index_hash[[ma.question_id.to_i, ma.matrix_answer_query_id.to_i, ma.looping_identifier]]] = ma.option_code
      end
      #Also consider the non-answered questions and put a dash instead of empty cell
      #This also affects the pivot tables in the goals sheets, but it also counts the empty answer in the total result
      #which probably is not the intended behaviour. Need discussion with Manuel.
      result.map! { |r| r.present? ? r : '-' }
      region2 = if respondent.region == 'Asia' || respondent.region == 'Oceania'
        'Asia/Oceania'
      elsif respondent.region == 'North America' ||
        respondent.region == 'Latin America and the Caribbean' ||
        respondent.region == 'Latin America & Caribbean'
        'Americas'
      else
        respondent.region
      end
      [region2, respondent.region, respondent.country] + result
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

    # Filters out only multiple choice questions from Section 3,
    # except those multiple choice questions, which are set up to use
    # a detaiuls field to enter a numeric value.
    def multi_answer_answers_rel(questions_rel)
      MultiAnswer.
        from('pt_multi_answer_answers_by_user_view multi_answers').joins(
          'JOIN (' + questions_rel.to_sql + ') questions' +
          " ON multi_answers.question_id = questions.id AND questions.answer_type_type = 'MultiAnswer'"
        ).
        where('NOT details_field') # this to exclude the "exact" etc pseudo-numeric questions
    end

    # Filters out only multiple choice questions from Section 3
    # which are set up to use a detaiuls field to enter a numeric value.
    def numeric_answer_answers_rel(questions_rel)
      MultiAnswer.
        from('pt_multi_answer_answers_by_user_view multi_answers').joins(
          'JOIN (' + questions_rel.to_sql + ') questions' +
          " ON multi_answers.question_id = questions.id AND questions.answer_type_type = 'MultiAnswer'"
        ).
        where('details_field') # this to include only the "exact" etc pseudo-numeric questions
    end

    # Filters out only matrix questions from Section 3.
    def matrix_answer_answers_rel(questions_rel)
      MatrixAnswer.
        from('pt_matrix_answer_answers_by_user_view matrix_answers').joins(
          'JOIN (' + questions_rel.to_sql + ') questions' +
          " ON matrix_answers.question_id = questions.id AND questions.answer_type_type = 'MatrixAnswer'"
        )
    end

    def questions_with_looping_identifiers
      result = {}
      @section_3_questions.each do |q|
        looping_section = q.section.self_and_ancestors.select{ |s| s.looping? }.first
        if looping_section.present?
          result[q.id] = looping_section.build_all_looping_identifiers
        end
      end
      result
    end

    def questions_with_matrix_queries
      result = {}
      matrix_answer_questions_rel(@section_3_questions).each do |q|
        result[q.id] = q.answer_type.matrix_answer_queries.
          includes(:matrix_answer_query_fields).
          where('matrix_answer_query_fields.is_default_language' => true)
      end
      result
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

    def column_index(column_number)
      index_hash = Hash.new {|hash,key| hash[key] = hash[key - 1].next }.merge({0 => "A"})
      index_hash[column_number]
    end

  end
end
