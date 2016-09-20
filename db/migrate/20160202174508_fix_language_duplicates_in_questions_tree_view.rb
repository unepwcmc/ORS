class FixLanguageDuplicatesInQuestionsTreeView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW api_questions_tree_view'
    execute view_sql('20160202174508', 'api_questions_tree_view')
  end

  def down
    execute 'DROP VIEW api_questions_tree_view'
    execute view_sql('20151109160327', 'api_questions_tree_view')
  end
end
