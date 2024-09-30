# DRY run
# RAILS_ENV=production rake sorting_bug_data_patch

# REAL run
# RAILS_ENV=production rake sorting_bug_data_patch[true]
task :sorting_bug_data_patch, [:real] => :environment do |t, args|
  real_run = args.real.present? # Otherwise DRY run.
  puts real_run ? 'REAL run' : 'DRY run'

  # To prevent this data patch script run more than one time, add a file as flag.
  patched_path = Rails.root.join('private', 'sorting_bug_data_patched.txt')
  abort("Patch script cannot run more than one times.") if real_run && File.exist?(patched_path)

  all_statement = []
  Question.where(answer_type_type: 'MatrixAnswer').each do |question|
    # matrix_answer_queries
    q_before = question.answer_type.matrix_answer_queries.map{|x| x.id }
    q_after = question.answer_type.matrix_answer_queries.order('id ASC').map{|x| x.id }

    # matrix_answer_options
    o_before = question.answer_type.matrix_answer_options.map{|x| x.id }
    o_after = question.answer_type.matrix_answer_options.order('id ASC').map{|x| x.id }

    if q_before != q_after || o_before != o_after
      puts "===Question ID #{question.id} need data patch==="
    end
    if q_before != q_after
      puts "--Queries:"
      puts "--before fix #{q_before}"
      puts "--after fix  #{q_after}"
      q_before.each_with_index do |before_id, index|
        after_id = q_after[index]
        if before_id != after_id
          affected_ids = AnswerPart.where(field_type_type: 'MatrixAnswerQuery', field_type_id: before_id).map{|x| x.id}
          puts "--was #{before_id} to #{after_id} for AnswerPart IDs #{affected_ids}"
          if affected_ids.present?
            statement = "UPDATE answer_parts SET field_type_id = #{after_id} WHERE id IN (#{affected_ids.join(',')});"
            puts statement
            all_statement << statement
          end
        end
      end
    end
    if o_before != o_after
      puts "--Options:"
      puts "--before fix #{o_before}"
      puts "--after fix  #{o_after}"
      o_before.each_with_index do |before_id, index|
        after_id = o_after[index]
        if before_id != after_id
          affected_ids = AnswerPartMatrixOption.where(matrix_answer_option_id: before_id).map{|x| x.id}
          puts "--was #{before_id} to #{after_id} for AnswerPartMatrixOption IDs #{affected_ids}"
          if affected_ids.present?
            statement = "UPDATE answer_part_matrix_options SET matrix_answer_option_id = #{after_id} WHERE id IN (#{affected_ids.join(',')});"
            puts statement
            all_statement << statement
          end
        end
      end
    end
  end

  if real_run
    file = File.open(patched_path, "w")
    all_statement.each do |statement|
      file.write("#{statement}\n")
      ActiveRecord::Base.connection.execute(statement)
    end
    file.close
  end
end
