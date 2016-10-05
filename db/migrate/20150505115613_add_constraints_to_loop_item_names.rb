class AddConstraintsToLoopItemNames < ActiveRecord::Migration
  def up
    # make loop_source_id NOT NULL & add foreign key constraint
    add_index :loop_item_names, :loop_source_id
    execute <<-SQL
      DELETE FROM loop_item_names
      WHERE id IN (
        SELECT lin.id
        FROM loop_item_names AS lin
        LEFT OUTER JOIN loop_sources AS ls ON lin.loop_source_id = ls.id
        WHERE ls.id IS NULL OR lin.loop_source_id IS NULL
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
      WHERE id IN (
        SELECT lin.id
        FROM loop_item_names AS lin
        LEFT OUTER JOIN loop_item_types AS lit ON lin.loop_item_type_id = lit.id
        WHERE lit.id IS NULL OR lin.loop_item_type_id IS NULL
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
