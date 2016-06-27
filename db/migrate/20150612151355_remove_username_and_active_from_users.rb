class RemoveUsernameAndActiveFromUsers < ActiveRecord::Migration
  def up
    if column_exists?(:users, :username)
      remove_column :users, :username
    end
    if column_exists?(:users, :active)
      remove_column :users, :active
    end
  end

  def down
  end
end
