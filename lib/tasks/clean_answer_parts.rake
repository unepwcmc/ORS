namespace :clean do
  task :answer_parts, [:questionnaire_id, :question_id] => :environment do |t, args|
    questionnaire = Questionnaire.find(args.questionnaire_id)

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


    answers.each do |answer|
      aps = answer.answer_parts
      most_recent = aps.order("updated_at DESC").first.id

      puts "Most recent answer_part:\n"
      puts "AnswerPart ID: #{most_recent}\n"
      puts "Answer ID: #{answer.id}\n\n"

      old_answer_parts = aps.where("id <> ?", most_recent)
      old_answer_parts.destroy_all

      puts "Other answer_parts destroyed!"
      puts "====================\n"
    end

    puts "List of cleaned answers:\n #{answers.map(&:id)}" if answers

  end
end
