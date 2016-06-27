class CreateViewsForRenderingApiResponses < ActiveRecord::Migration
  def up
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_sections_tree_view CASCADE'
    execute view_sql('20151109160327', 'api_sections_tree_view')
    execute view_sql('20151109160327', 'api_questions_tree_view')
    execute view_sql('20151109160327', 'api_sections_looping_contexts_view')
    execute view_sql('20151109160327', 'api_answers_view')
  end

  def down
    execute 'DROP VIEW api_answers_view'
    execute 'DROP VIEW api_sections_looping_contexts_view'
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_sections_tree_view'
    execute view_sql('20151030151237', 'api_sections_tree_view')
    execute view_sql('20151030151237', 'api_questions_tree_view')
  end
end
