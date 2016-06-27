class RemoveZombieAlertsAndCreateForeignKeyConstraints < ActiveRecord::Migration
  def up
    execute <<-SQL
      WITH zombie_alerts AS (
        SELECT * FROM alerts
        EXCEPT
        SELECT alerts.* FROM alerts
        JOIN reminders ON alerts.reminder_id = reminders.id
        JOIN deadlines ON alerts.deadline_id = deadlines.id
      )
      DELETE FROM alerts a1
      USING zombie_alerts a2
      WHERE a1.id = a2.id;
    SQL
    change_column :alerts, :reminder_id, :integer, null: false
    change_column :alerts, :deadline_id, :integer, null: false
    add_foreign_key(:alerts, :reminders, {:column => :reminder_id, :dependent => :delete})
    add_foreign_key(:alerts, :deadlines, {:column => :deadline_id, :dependent => :delete})
  end

  def down
  end
end
