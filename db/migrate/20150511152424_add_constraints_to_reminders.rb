class AddConstraintsToReminders < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE reminders SET title = '(empty)'
      WHERE title IS NULL
    SQL
    change_column :reminders, :title, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE reminders SET created_at = NOW() WHERE created_at IS NULL"
    change_column :reminders, :created_at, :datetime, null: false
    execute "UPDATE reminders SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :reminders, :updated_at, :datetime, null: false
  end

  def down
    change_column :reminders, :title, :string, null: true
    change_column :reminders,
      :created_at, :datetime, null: true
    change_column :reminders,
      :updated_at, :datetime, null: true
  end
end
