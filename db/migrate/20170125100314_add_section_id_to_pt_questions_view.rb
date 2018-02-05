class AddSectionIdToPtQuestionsView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view'
    execute 'DROP VIEW IF EXISTS pt_questions_view'
    execute view_sql('20170125100314', 'pt_questions_view')
    execute view_sql('20170125094150', 'pt_multi_answer_answers_by_user_view')
  end

  def down
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view'
    execute 'DROP VIEW IF EXISTS pt_questions_view'
    execute view_sql('20170124102315', 'pt_questions_view')
    execute view_sql('20170125094150', 'pt_multi_answer_answers_by_user_view')
  end
end
