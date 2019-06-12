class AddApiMatrixAnswerDropOptionsView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS api_matrix_answer_drop_options_view'
    execute view_sql('20190510094856', 'api_matrix_answer_drop_options_view')
  end

  def down
    execute 'DROP VIEW api_matrix_answer_drop_options_view'
  end
end
