class CreateQuestionLoopingContextsView < ActiveRecord::Migration
  def up
    execute view_sql('20151110093219', 'api_questions_looping_contexts_view')
  end

  def down
    execute 'DROP VIEW api_questions_looping_contexts_view'
  end
end
