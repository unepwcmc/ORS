class AddConstraintsToLoopItemNames < ActiveRecord::Migration
  def up
    # make loop_source_id NOT NULL & add foreign key constraint
    add_index :loop_item_names, :loop_source_id
    execute <<-SQL
      DELETE FROM loop_item_names
      WHERE loop_source_id IS NULL
      OR loop_source_id NOT IN (
        SELECT id FROM loop_sources
      )
    SQL

    change_column :loop_item_names,
      :loop_source_id, :integer, null: false
    add_foreign_key :loop_item_names,
      :loop_sources, {
        column: :loop_source_id,
        dependent: :delete
      }

    # make loop_item_type_id NOT NULL & add foreign key constraint
    add_index :loop_item_names, :loop_item_type_id
    execute <<-SQL
      DELETE FROM loop_item_names
      WHERE loop_item_type_id IS NULL
      OR loop_item_type_id NOT IN (
        SELECT id FROM loop_item_types
      )
    SQL

    change_column :loop_item_names,
      :loop_item_type_id, :integer, null: false
    add_foreign_key :loop_item_names,
      :loop_item_types, {
        column: :loop_item_type_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE loop_item_names SET created_at = NOW() WHERE created_at IS NULL"
    change_column :loop_item_names, :created_at, :datetime, null: false
    execute "UPDATE loop_item_names SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :loop_item_names, :updated_at, :datetime, null: false
  end

  def down
    remove_index :loop_item_names, :loop_source_id
    change_column :loop_item_names,
      :loop_source_id, :integer, null: true
    remove_foreign_key :loop_item_names, column: :loop_source_id

    remove_index :loop_item_names, :loop_item_type_id
    change_column :loop_item_names,
      :loop_item_type_id, :integer, null: true
    remove_foreign_key :loop_item_names, column: :loop_item_type_id

    change_column :loop_item_names,
      :created_at, :datetime, null: true
    change_column :loop_item_names,
      :updated_at, :datetime, null: true
  end
end
