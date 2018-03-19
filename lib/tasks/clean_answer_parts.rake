namespace :clean do
  task :answer_parts, [:questionnaire_id, :question_id] => :environment do |t, args|
    require 'csv'

    where_question = args.question_id ? "AND answers.question_id = #{args.question_id}" : ''

    sql = <<-SQL
      SELECT answers.id
      FROM answers
      INNER JOIN answer_parts ap ON ap.answer_id = answers.id
      RIGHT OUTER JOIN questions q ON answers.question_id = q.id
      WHERE ap.field_type_type = 'MultiAnswerOption' #{where_question}
      GROUP BY answers.id
      HAVING COUNT(answers.id) > 1
    SQL

    answers = Answer.find_by_sql(sql)

    puts "Nothing to clean!" unless answers.present?


    answers.each_with_index do |answer, index|
      aps = answer.answer_parts
      most_recent = aps.order("updated_at DESC").first.id

      puts "Most recent answer_part:\n"
      puts "AnswerPart ID: #{most_recent}\n"
      puts "Answer ID: #{answer.id}\n\n"

      to_csv(aps, most_recent, index)

      old_answer_parts = aps.where("id <> ?", most_recent)
      old_answer_parts.destroy_all

      puts "Other answer_parts destroyed!"
      puts "====================\n"
    end

    puts "List of cleaned answers:\n #{answers.map(&:id)}" if answers.present?

  end

  def to_csv(answer_parts, most_recent, index)
    filename = 'deleted_answers.csv'

    if index == 0
      columns = ['Answer', 'Text', 'Part ID', 'Answer ID', 'MAO ID', 'MA ID',
                 'Question ID', 'User ID', 'Is deleted', 'Question Title',
                 'First name', 'Last name','Country', 'Region', 'Timestamp', 'Precise Timestamp']

      CSV.open(filename, 'w') { |csv| csv << columns }
    end

    ans = answer_parts.map do |ap|
      user = ap.answer.user
      [ap.field_type.multi_answer_option_fields.first.option_text, ap.details_text, ap.id,
       ap.answer.id, ap.field_type_id, ap.field_type.multi_answer_id, ap.answer.question.id,
       user.id, ap.id != most_recent, ap.answer.question.title, user.first_name, user.last_name,
       user.country, user.region, ap.updated_at, ap.updated_at.to_f]
    end

    CSV.open(filename, 'a') do |csv|
      ans.each do |a|
        csv << a
      end
    end
  end
end
