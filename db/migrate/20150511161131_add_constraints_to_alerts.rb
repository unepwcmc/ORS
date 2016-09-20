class AddConstraintsToAlerts < ActiveRecord::Migration
  def up
    # make reminder_id NOT NULL & add foreign key constraint
    add_index :alerts, :reminder_id
    execute <<-SQL
      WITH alerts_to_delete AS (
        SELECT * FROM alerts
        EXCEPT
        SELECT alerts.*
        FROM alerts
        JOIN reminders
        ON alerts.reminder_id = reminders.id
      )
      DELETE FROM alerts t
      USING alerts_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :alerts,
      :reminder_id, :integer, null: false
    # lazy way of handling inconsistent schemas across instances
    execute 'ALTER TABLE alerts DROP CONSTRAINT IF EXISTS alerts_reminder_id_fk'
    add_foreign_key :alerts,
      :reminders, {
        column: :reminder_id,
        dependent: :delete
      }

    # make deadline_id NOT NULL & add foreign key constraint
    add_index :alerts, :deadline_id
    execute <<-SQL
      WITH alerts_to_delete AS (
        SELECT * FROM alerts
        EXCEPT
        SELECT alerts.*
        FROM alerts
        JOIN deadlines
        ON alerts.deadline_id = deadlines.id
      )
      DELETE FROM alerts t
      USING alerts_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :alerts,
      :deadline_id, :integer, null: false
    # lazy way of handling inconsistent schemas across instances
    execute 'ALTER TABLE alerts DROP CONSTRAINT IF EXISTS alerts_deadline_id_fk'
    add_foreign_key :alerts,
      :deadlines, {
        column: :deadline_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE alerts SET created_at = NOW() WHERE created_at IS NULL"
    change_column :alerts, :created_at, :datetime, null: false
    execute "UPDATE alerts SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :alerts, :updated_at, :datetime, null: false
  end

  def down
    remove_index :alerts, :reminder_id
    change_column :alerts,
      :reminder_id, :integer, null: true
    remove_foreign_key :alerts, column: :reminder_id

    remove_index :alerts, :deadline_id
    change_column :alerts,
      :deadline_id, :integer, null: true
    remove_foreign_key :alerts, column: :deadline_id

    change_column :alerts,
      :created_at, :datetime, null: true
    change_column :alerts,
      :updated_at, :datetime, null: true
  end
end
