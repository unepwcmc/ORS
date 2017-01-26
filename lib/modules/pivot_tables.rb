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
    end

    def run
      if !File.directory? @dir_path
        FileUtils.mkdir_p(@dir_path)
      end
      Rails.logger.debug("#{Time.now} Started generating pivot tables")
      elapsed_time = Benchmark.realtime do
        Axlsx::Package.new do |p|
          create_data_sheet(p.workbook, @questionnaire)
          # create_multi_answer_questions_sheet(p.workbook, @questionnaire)
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

    def create_data_sheet(workbook, questionnaire)
      questions = Question.
        from('pt_questions_view questions').
        where(
          questionnaire_id: questionnaire.id,
          root_section: 'Section 3',
          answer_type_type: ['MultiAnswer', 'MatrixAnswer']
        ).
        order(:lft)

      questions_with_looping_identifiers = {}
      questions.each do |q|
        looping_section = q.section.self_and_ancestors.select{ |s| s.looping? }.first
        if looping_section.present?
          questions_with_looping_identifiers[q.id] = looping_section.build_all_looping_identifiers
        end
      end

      questions_with_matrix_queries = {}
      questions.where(answer_type_type: 'MatrixAnswer').each do |q|
        questions_with_matrix_queries[q.id] = q.answer_type.matrix_answer_queries.includes(:matrix_answer_query_fields).where('matrix_answer_query_fields.is_default_language' => true)
      end

      headers_with_looping_contexts = []
      identifiers_with_looping_contexts = []

      questions.each do |q|
        header_segments, identifier_segments = [[q.uidentifier]], [[q.id]]
        matrix_queries = questions_with_matrix_queries[q.id]
        matrix_header_segments, matrix_identifier_segments = if matrix_queries.present?
          [
            matrix_queries.map { |mq| matrix_query_identifier_as_text(mq.id, 'en') },
            matrix_queries.map { |mq| mq.id }
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
          headers_with_looping_contexts << hs.flatten.compact.join(' | ')
        end
        identifier_segments.each do |is|
          identifiers_with_looping_contexts << is.flatten
        end
      end

      respondents = User.
        select([:user_id, :country, :region, :status]).
        from('api_respondents_view users').
        where(status: 'Submitted')
      
      workbook.add_worksheet(name: 'Data') do |sheet|
        sheet.add_row ['REGION_Ramsar', 'CNTRY_Ramsar'] + headers_with_looping_contexts
        respondents.each do |respondent|
          sheet.add_row data_row_for_respondent(questionnaire, respondent, identifiers_with_looping_contexts)
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
    def data_row_for_respondent(questionnaire, respondent, identifiers_with_looping_contexts)
      index_hash = Hash[identifiers_with_looping_contexts.each_with_index.map { |x, i| [x, i] }]
      result = Array.new(identifiers_with_looping_contexts.size)
      #tmp = Hash[identifiers_with_looping_contexts.map {|x| [x, nil]}]
      multi_answers_base = MultiAnswer.
        from('pt_multi_answer_answers_by_user_view multi_answers').
        joins('JOIN pt_questions_view q ON multi_answers.question_id = q.id').
        where(
          'q.questionnaire_id' => questionnaire.id,
          'q.root_section' => 'Section 3',
          user_id: respondent.user_id
        )
      # multi answer question answers
      multi_answers = multi_answers_base.
        where('NOT details_field') # this to exclude the "exact" etc pseudo-numeric questions
      multi_answers.each do |ma|
        result[index_hash[[ma.question_id.to_i, nil, ma.looping_identifier]]] = ma.option_code
      end
      # pseudo-numeric question answers
      numeric_answers = multi_answers_base.
        where('details_field') # this to only include the "exact" etc pseudo-numeric questions
      numeric_answers.each do |na|
        result[index_hash[[na.question_id.to_i, nil, na.looping_identifier]]] = na.details_text
      end
      # matrix answer question answers
      matrix_answers = MatrixAnswer.
        from('pt_matrix_answer_answers_by_user_view matrix_answers').
        joins('JOIN pt_questions_view q ON matrix_answers.question_id = q.id').
        where(
          'q.questionnaire_id' => questionnaire.id,
          'q.root_section' => 'Section 3',
          user_id: respondent.user_id
        )
      matrix_answers.each do |ma|
        result[index_hash[[ma.question_id.to_i, ma.matrix_answer_query_id.to_i, ma.looping_identifier]]] = ma.option_code
      end
      [respondent.region, respondent.country] + result
    end

    def create_multi_answer_questions_sheet(workbook, questionnaire)
      workbook.add_worksheet(name: 'Multi Answer Questions') do |sheet|
        sheet.add_row [Date.today.to_formatted_s(:long_ordinal), questionnaire.title]
        sheet.add_row []
        first_row = 3
        max_cols = 0
        multi_answer_questions = Question.
          from('pt_questions_view questions').
          where(
            questionnaire_id: questionnaire.id,
            answer_type_type: 'MultiAnswer'
          ).
          order(:lft)
        multi_answer_questions.each do |question|
          data_rows = data_rows_for_multi_answer_question(question)        
          data_rows.each do |row|
            sheet.add_row row, style: Axlsx::STYLE_THIN_BORDER
          end
          num_of_rows = data_rows.size
          num_of_cols = data_rows[2].size
          max_cols = num_of_cols if num_of_cols > max_cols # track this to know total num of cols in sheet
          do_the_cell_merging(sheet, first_row, num_of_rows, num_of_cols)
          first_row = first_row + num_of_rows
        end
        col_widths = [16, 16] + Array.new(max_cols - 2){ 9 }
        sheet.column_widths *col_widths
      end
    end

    def do_the_cell_merging(sheet, first_row, num_of_rows, num_of_cols)
      last_col_index = column_index(num_of_cols - 1)
      one_before_last_col_index = column_index(num_of_cols - 2)
      sheet.merge_cells("A#{first_row}:B#{first_row+1}")
      sheet.merge_cells("C#{first_row}:#{last_col_index}#{first_row}")
      # for each answer option column merge the geader cells above Nb / %
      (2..num_of_cols-3).step(2) do |i|
        col1_number = i
        col1_index = column_index(col1_number)
        col2_index = column_index(col1_number + 1)
        sheet.merge_cells("#{col1_index}#{first_row + 1}:#{col2_index}#{first_row + 1}")
      end
      sheet.merge_cells("#{last_col_index}#{first_row+1}:#{last_col_index}#{first_row + 2}")
      sheet.merge_cells("#{one_before_last_col_index}#{first_row+1}:#{one_before_last_col_index}#{first_row + 2}")
      last_row = first_row + num_of_rows
      sheet.merge_cells("A#{last_row - 2}:B#{last_row - 2}")
    end

    def data_rows_for_multi_answer_question(question)
      option_codes = Question.select('option_code').
        from('pt_multi_answer_option_codes_view questions').
        where(question_id: question.id).
        uniq.
        map{ |q| q['option_code'] }
      option_codes.unshift('EMPTY') # no answer
      rows = []
      rows << ['', '', "#{question.uidentifier} Data"]
      rows << ['', ''] +
        option_codes.map{ |oc| [oc, '']}.flatten +
        ['Total Nb of CP', 'Total %']
      rows << ['REGION_Ramsar2', 'REGION_Ramsar'] +
        option_codes.map{ |oc| ['Nb of CP', '%']}.flatten +
        ['', '']

      # pivot query to fetch all values in one go
      option_codes_str = option_codes.map{ |oc| "''#{oc}''" }.join(', ')
      option_codes_return_type_str = option_codes.map{ |oc| "#{oc} INT" }.join (', ')
      # source_sql is a SQL statement that produces the source set of data.
      # This statement must return one row_name column, one category column,
      # and one value column. It may also have one or more "extra" columns. 
      # The row_name column must be first. The category and value columns must be 
      # the last two columns, in that order. Any columns between row_name and
      # category are treated as "extra". The "extra" columns are expected to be
      # the same for all rows with the same row_name value.
      source_sql = <<-SQL
        SELECT region, option_code, count
        FROM pt_multi_answer_answers_by_question_view
        WHERE question_id = #{question.id}
        AND option_code IN (#{option_codes_str})
        ORDER BY 1,2
      SQL
      # category_sql is a SQL statement that produces the set of categories.
      # This statement must return only one column. It must produce at least
      # one row, or an error will be generated. 
      category_sql = "SELECT * FROM UNNEST(ARRAY[#{option_codes_str}])"
      pivot_sql = <<-SQL
        SELECT *
        FROM crosstab(
          '#{source_sql}',
          '#{category_sql}'
        )
        AS ct(region text, #{option_codes_return_type_str});
      SQL
      result = ActiveRecord::Base.connection.execute(pivot_sql)
      result_hash = Hash[result.map{ |row| [row.delete('region'), row] }]
      total_for_all_regions = 0
      totals_for_options = Hash.new(0)
      RAMSAR_REGIONS.keys.each do |region|
        result_for_region = result_hash[region]
        total_for_region = result_for_region && result_for_region.values.map(&:to_i).sum || 0
        total_for_all_regions += total_for_region
        rows << [RAMSAR_REGIONS[region], region] +
          option_codes.map do |oc|
            cnt = result_for_region && result_for_region[oc.downcase].to_i || 0
            totals_for_options[oc] += cnt
            pct = if total_for_region > 0
              ((cnt.to_f / total_for_region) * 100).round
            else 
              0
            end
            [cnt, pct]
          end.flatten +
          [total_for_region, '100%']
      end
      rows << ["Grand Total", ''] +
        option_codes.map do |oc|
          cnt = totals_for_options[oc]
          pct = if total_for_all_regions > 0
            ((cnt.to_f / total_for_all_regions) * 100).round
          else 
            0
          end
          [cnt, pct]
        end.flatten +
        [total_for_all_regions, '100%']
      rows << []
    end

    RAMSAR_REGIONS = {
      'Africa' => 'Africa',
      'Asia/Oceania' => 'All Asia',
      'Europe' => 'Europe',
      'North/Latin' => 'Americas'
    }

    def column_index(column_number)
      index_hash = Hash.new {|hash,key| hash[key] = hash[key - 1].next }.merge({0 => "A"})
      index_hash[column_number]
    end
  end
end
