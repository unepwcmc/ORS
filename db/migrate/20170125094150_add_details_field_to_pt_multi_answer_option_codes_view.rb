class AddDetailsFieldToPtMultiAnswerOptionCodesView < ActiveRecord::Migration
  def up
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_option_codes_view'
    execute view_sql('20170125094150', 'pt_multi_answer_option_codes_view')
    execute view_sql('20170125094150', 'pt_multi_answer_answers_by_user_view')
  end

  def down
    execute 'DROP VIEW IF EXISTS pt_multi_answer_answers_by_user_view'
    execute 'DROP VIEW IF EXISTS pt_multi_answer_option_codes_view'
    execute view_sql('20170124105651', 'pt_multi_answer_option_codes_view')
    execute view_sql('20170124110749', 'pt_multi_answer_answers_by_user_view')
  end
end
