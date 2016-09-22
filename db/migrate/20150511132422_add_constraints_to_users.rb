class AddConstraintsToUsers < ActiveRecord::Migration
  def up
    # make creator_id NOT NULL & add foreign key constraint
    add_index :users, :creator_id

    execute <<-SQL
      WITH users_to_nullify AS (
        SELECT * FROM users WHERE creator_id IS NOT NULL AND creator_id != 0
        EXCEPT
        SELECT users.* FROM users
        JOIN users c ON c.id = users.creator_id
      )
      UPDATE users t
      SET creator_id = NULL
      FROM users_to_nullify tn
      WHERE t.id = tn.id
    SQL

    # sadly, can't create a foreign key because of some odd logic that checks if creator_id == 0

    # make timestamps NOT NULL
    execute "UPDATE users SET created_at = NOW() WHERE created_at IS NULL"
    change_column :users, :created_at, :datetime, null: false
    execute "UPDATE users SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :users, :updated_at, :datetime, null: false
  end

  def down
    change_column :users,
      :created_at, :datetime, null: true
    change_column :users,
      :updated_at, :datetime, null: true
  end
end
