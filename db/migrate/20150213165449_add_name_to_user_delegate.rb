class AddNameToUserDelegate < ActiveRecord::Migration
  def up
    remove_column :user_delegates, :details
  end

  def down
    add_column :user_delegates, :details, :string
  end
end
