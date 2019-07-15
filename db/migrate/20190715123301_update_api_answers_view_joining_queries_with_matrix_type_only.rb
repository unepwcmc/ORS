class UpdateApiAnswersViewJoiningQueriesWithMatrixTypeOnly < ActiveRecord::Migration
  def up
    execute 'DROP VIEW api_answers_view'
    execute view_sql('20190715123301', 'api_answers_view')
  end

  def down
    execute 'DROP VIEW api_answers_view'
    execute view_sql('20190510150637', 'api_answers_view')
  end
end
