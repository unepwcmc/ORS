class CreateApiViews < ActiveRecord::Migration
  def up
    execute 'DROP VIEW api_questionnaires_view'
    execute view_sql('20151030151237', 'api_questionnaires_view')
    execute view_sql('20151030151237', 'api_respondents_view')
    execute view_sql('20151030151237', 'api_sections_view')
    execute view_sql('20151030151237', 'api_sections_tree_view')
    execute view_sql('20151030151237', 'api_questions_view')
    execute view_sql('20151030151237', 'api_multi_answer_options_view')
    execute view_sql('20151030151237', 'api_range_answer_options_view')
    execute view_sql('20151030151237', 'api_questions_tree_view')
  end

  def down
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_questions_view'
    execute 'DROP VIEW api_sections_tree_view'
    execute 'DROP VIEW api_sections_view'
    execute 'DROP VIEW api_multi_answer_options_view'
    execute 'DROP VIEW api_range_answer_options_view'
  end
end
