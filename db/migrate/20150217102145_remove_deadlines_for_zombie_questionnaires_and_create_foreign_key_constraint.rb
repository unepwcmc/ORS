class RemoveDeadlinesForZombieQuestionnairesAndCreateForeignKeyConstraint < ActiveRecord::Migration
  def up
    execute <<-SQL
      WITH deadlines_for_zombie_questionnaires AS (
      SELECT * FROM deadlines
      EXCEPT
      SELECT deadlines.* FROM deadlines JOIN questionnaires ON questionnaires.id = deadlines.questionnaire_id
      )
      DELETE FROM deadlines d1
      USING deadlines_for_zombie_questionnaires d2
      WHERE d1.id = d2.id;
    SQL
    change_column :deadlines, :questionnaire_id, :integer, null: false
    add_foreign_key(:deadlines, :questionnaires, {:column => :questionnaire_id, :dependent => :delete})
  end

  def down
  end
end
