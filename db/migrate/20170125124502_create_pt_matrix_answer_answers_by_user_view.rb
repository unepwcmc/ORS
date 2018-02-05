class CreatePtMatrixAnswerAnswersByUserView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS pt_matrix_answer_answers_by_user_view CASCADE'
    execute view_sql('20170125124502', 'pt_matrix_answer_answers_by_user_view')
  end

  def down
    execute 'DROP VIEW IF EXISTS pt_matrix_answer_answers_by_user_view CASCADE'
  end
end
