class AddConstraintsToAssignments < ActiveRecord::Migration
  def up
    # make user_id NOT NULL & add foreign key constraint
    add_index :assignments, :user_id
    execute <<-SQL
      WITH assignments_to_delete AS (
        SELECT * FROM assignments
        EXCEPT
        SELECT assignments.*
        FROM assignments
        JOIN users
        ON assignments.user_id = users.id
      )
      DELETE FROM assignments t
      USING assignments_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :assignments,
      :user_id, :integer, null: false
    add_foreign_key :assignments,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make role_id NOT NULL & add foreign key constraint
    add_index :assignments, :role_id
    execute <<-SQL
      WITH assignments_to_delete AS (
        SELECT * FROM assignments
        EXCEPT
        SELECT assignments.*
        FROM assignments
        JOIN roles
        ON assignments.role_id = roles.id
      )
      DELETE FROM assignments t
      USING assignments_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :assignments,
      :role_id, :integer, null: false
    add_foreign_key :assignments,
      :roles, {
        column: :role_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE assignments SET created_at = NOW() WHERE created_at IS NULL"
    change_column :assignments, :created_at, :datetime, null: false
    execute "UPDATE assignments SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :assignments, :updated_at, :datetime, null: false
  end

  def down
    remove_index :assignments, :user_id
    change_column :assignments,
      :user_id, :integer, null: true
    remove_foreign_key :assignments, column: :user_id

    remove_index :assignments, :role_id
    change_column :assignments,
      :role_id, :integer, null: true
    remove_foreign_key :assignments, column: :role_id

    change_column :assignments,
      :created_at, :datetime, null: true
    change_column :assignments,
      :updated_at, :datetime, null: true
  end
end
