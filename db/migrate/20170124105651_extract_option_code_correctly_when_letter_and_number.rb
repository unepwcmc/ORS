class ExtractOptionCodeCorrectlyWhenLetterAndNumber < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_question_view'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_option_codes_view'
    execute view_sql('20170124105651', 'pt_multi_answer_option_codes_view')
    execute view_sql('20161121125541', 'pt_multi_answer_answers_by_user_view')
    execute view_sql('20161121125541', 'pt_multi_answer_answers_by_question_view')
  end

  def down
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_question_view'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_option_codes_view'
    execute view_sql('20161121125541', 'pt_multi_answer_option_codes_view')
    execute view_sql('20161121125541', 'pt_multi_answer_answers_by_user_view')
    execute view_sql('20161121125541', 'pt_multi_answer_answers_by_question_view')
  end
end
