class AddMatrixQuestionsToQuestionsViews < ActiveRecord::Migration
  def up
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_questions_view'

    execute view_sql('20190513103623', 'api_questions_view')
    execute view_sql('20190513103623', 'api_questions_tree_view')
  end

  def down
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_questions_view'

    execute view_sql('20151030151237', 'api_questions_view')
    execute view_sql('20160202174508', 'api_questions_tree_view')
  end
end
