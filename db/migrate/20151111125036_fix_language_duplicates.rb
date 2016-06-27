class FixLanguageDuplicates < ActiveRecord::Migration
  def up
    execute 'DROP VIEW api_questions_looping_contexts_view'
    execute 'DROP VIEW api_sections_looping_contexts_view'
    execute view_sql('20151111125036', 'api_sections_looping_contexts_view')
    execute view_sql('20151111125036', 'api_questions_looping_contexts_view')
  end

  def down
    execute 'DROP VIEW api_questions_looping_contexts_view'
    execute 'DROP VIEW api_sections_looping_contexts_view'
    execute view_sql('20151109160327', 'api_sections_looping_contexts_view')
    execute view_sql('20151110093219', 'api_questions_looping_contexts_view')
  end
end
