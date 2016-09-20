class AddConstraintsToPersistentErrors < ActiveRecord::Migration
  def up
    # make user_id NOT NULL & add foreign key constraint
    add_index :persistent_errors, :user_id
    execute <<-SQL
      WITH persistent_errors_to_delete AS (
        SELECT * FROM persistent_errors
        EXCEPT
        SELECT persistent_errors.* FROM persistent_errors
        JOIN users ON users.id = persistent_errors.user_id
      )
      DELETE FROM persistent_errors t
      USING persistent_errors_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :persistent_errors,
      :user_id, :integer, null: false
    add_foreign_key :persistent_errors,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE persistent_errors SET created_at = NOW() WHERE created_at IS NULL"
    change_column :persistent_errors, :created_at, :datetime, null: false
    execute "UPDATE persistent_errors SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :persistent_errors, :updated_at, :datetime, null: false
  end

  def down
    remove_index :persistent_errors, :user_id
    change_column :persistent_errors,
      :user_id, :integer, null: true
    remove_foreign_key :persistent_errors, column: :user_id

    change_column :persistent_errors,
      :created_at, :datetime, null: true
    change_column :persistent_errors,
      :updated_at, :datetime, null: true
  end
end
