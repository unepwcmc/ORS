class AddApiMatrixAnswerOptionsView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS api_matrix_answer_options_view'
    execute view_sql('20190506122830', 'api_matrix_answer_options_view')
  end

  def down
    execute 'DROP VIEW api_matrix_answer_options_view'
  end
end
