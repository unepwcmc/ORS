class IncludeOptionsInApiAnswersView < ActiveRecord::Migration
  def up
    execute view_sql('20151111121003', 'api_answers_view')
  end

  def down
    execute view_sql('20151109160327', 'api_answers_view')
  end
end
