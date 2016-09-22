class AddConstraintsToUserDelegates < ActiveRecord::Migration
  def up
    # make user_id NOT NULL & add foreign key constraint
    add_index :user_delegates, :user_id
    execute <<-SQL
      WITH user_delegates_to_delete AS (
        SELECT * FROM user_delegates
        EXCEPT
        SELECT user_delegates.*
        FROM user_delegates
        JOIN users
        ON user_delegates.user_id = users.id
      )
      DELETE FROM user_delegates t
      USING user_delegates_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :user_delegates,
      :user_id, :integer, null: false
    add_foreign_key :user_delegates,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make delegate_id NOT NULL & add foreign key constraint
    add_index :user_delegates, :delegate_id
    execute <<-SQL
      WITH user_delegates_to_delete AS (
        SELECT * FROM user_delegates
        EXCEPT
        SELECT user_delegates.*
        FROM user_delegates
        JOIN users
        ON user_delegates.delegate_id = users.id
      )
      DELETE FROM user_delegates t
      USING user_delegates_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :user_delegates,
      :delegate_id, :integer, null: false
    add_foreign_key :user_delegates,
      :users, {
        column: :delegate_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE user_delegates SET created_at = NOW() WHERE created_at IS NULL"
    change_column :user_delegates, :created_at, :datetime, null: false
    execute "UPDATE user_delegates SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :user_delegates, :updated_at, :datetime, null: false
  end

  def down
    remove_index :user_delegates, :user_id
    change_column :user_delegates,
      :user_id, :integer, null: true
    remove_foreign_key :user_delegates, column: :user_id

    remove_index :user_delegates, :delegate_id
    change_column :user_delegates,
      :delegate_id, :integer, null: true
    remove_foreign_key :user_delegates, column: :delegate_id

    change_column :user_delegates,
      :created_at, :datetime, null: true
    change_column :user_delegates,
      :updated_at, :datetime, null: true
  end
end
