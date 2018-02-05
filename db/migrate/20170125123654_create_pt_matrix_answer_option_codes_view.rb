class CreatePtMatrixAnswerOptionCodesView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS pt_matrix_answer_option_codes_view CASCADE'
    execute view_sql('20170125123654', 'pt_matrix_answer_option_codes_view')
  end

  def down
    execute 'DROP VIEW IF EXISTS pt_matrix_answer_option_codes_view CASCADE'
  end
end
