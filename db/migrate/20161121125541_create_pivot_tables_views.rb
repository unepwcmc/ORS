class CreatePivotTablesViews < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS pt_questions_view CASCADE'
    execute view_sql('20161121125541', 'pt_questions_view')
    execute 'DROP VIEW IF EXISTS pt_multi_answer_option_codes_view CASCADE'
    execute view_sql('20161121125541', 'pt_multi_answer_option_codes_view')
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view CASCADE'
    execute view_sql('20161121125541', 'pt_multi_answer_answers_by_user_view')
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_question_view CASCADE'
    execute view_sql('20161121125541', 'pt_multi_answer_answers_by_question_view')
    execute 'CREATE EXTENSION IF NOT EXISTS tablefunc'
  end

  def down
    execute 'DROP VIEW IF EXISTS pt_questions_view CASCADE'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_option_codes_view CASCADE'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view CASCADE'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_question_view CASCADE'
  end
end
