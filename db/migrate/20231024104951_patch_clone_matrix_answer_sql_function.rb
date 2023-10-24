class PatchCloneMatrixAnswerSqlFunction < ActiveRecord::Migration
  def up
    execute function_sql('20231024104951', 'patch_clone_matrix_answer_sql_function')
  end

  def down
  end
end
