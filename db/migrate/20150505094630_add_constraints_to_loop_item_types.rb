class AddConstraintsToLoopItemTypes < ActiveRecord::Migration
  def up
    # add foreign key constraint
    # index on parent_id already in place
    execute <<-SQL
      DELETE FROM loop_item_types
      WHERE id IN (
        SELECT lit.id
        FROM loop_item_types AS lit
        LEFT OUTER JOIN loop_item_types AS lit2 ON lit.parent_id = lit2.id
        WHERE lit2.id IS NULL AND lit.parent_id IS NOT NULL
      )
    SQL

    add_foreign_key :loop_item_types,
      :loop_item_types, {
        column: :parent_id,
        dependent: :delete
      }

    # add foreign key constraint
    add_index :loop_item_types, :loop_source_id
    execute <<-SQL
      DELETE FROM loop_item_types
      WHERE loop_source_id IS NOT NULL
      AND loop_source_id NOT IN (
        SELECT id FROM loop_sources
      )
    SQL

    add_foreign_key :loop_item_types,
      :loop_sources, {
        column: :loop_source_id,
        dependent: :delete
      }

    # add foreign key constraint
    add_index :loop_item_types, :filtering_field_id
    execute <<-SQL
      DELETE FROM loop_item_types
      WHERE filtering_field_id IS NOT NULL
      AND filtering_field_id NOT IN (
        SELECT id FROM filtering_fields
      )
    SQL

    add_foreign_key :loop_item_types,
      :filtering_fields, {
        column: :filtering_field_id,
        dependent: :nullify
      }

    execute "UPDATE loop_item_types SET name = '(empty)' WHERE name IS NULL"
    change_column :loop_item_types,
      :name, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE loop_item_types SET created_at = NOW() WHERE created_at IS NULL"
    change_column :loop_item_types, :created_at, :datetime, null: false
    execute "UPDATE loop_item_types SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :loop_item_types, :updated_at, :datetime, null: false
  end

  def down
    remove_foreign_key :loop_item_types, column: :parent_id
    remove_index :loop_item_types, :loop_source_id
    remove_foreign_key :loop_item_types, column: :loop_source_id
    remove_index :loop_item_types, :filtering_field_id
    remove_foreign_key :loop_item_types, column: :filtering_field_id

    change_column :loop_item_types,
      :name, :string, null: true

    change_column :loop_item_types,
      :created_at, :datetime, null: true
    change_column :loop_item_types,
      :updated_at, :datetime, null: true
  end
end
