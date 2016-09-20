class AddConstraintsToRoles < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE roles SET name = '(empty)'
      WHERE name IS NULL
    SQL
    change_column :roles, :name, :string, null: false

    # make timestamps NOT NULL
    execute "UPDATE roles SET created_at = NOW() WHERE created_at IS NULL"
    change_column :roles, :created_at, :datetime, null: false
    execute "UPDATE roles SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :roles, :updated_at, :datetime, null: false
  end

  def down
    change_column :roles, :name, :string, null: true
    change_column :roles,
      :created_at, :datetime, null: true
    change_column :roles,
      :updated_at, :datetime, null: true
  end
end
