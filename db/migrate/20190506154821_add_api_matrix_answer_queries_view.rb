class AddApiMatrixAnswerQueriesView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS api_matrix_answer_queries_view'
    execute view_sql('20190506154821', 'api_matrix_answer_queries_view')
  end

  def down
    execute 'DROP VIEW api_matrix_answer_queries_view'
  end
end
