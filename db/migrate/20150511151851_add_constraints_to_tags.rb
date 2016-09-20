class AddConstraintsToTags < ActiveRecord::Migration
  def up
    execute "DELETE FROM tags WHERE name IS NULL"
    change_column :tags, :name, :string, null: false
  end

  def down
    change_column :tags, :name, :string, null: true
  end
end
