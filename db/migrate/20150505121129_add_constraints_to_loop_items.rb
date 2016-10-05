class AddConstraintsToLoopItems < ActiveRecord::Migration
  def up
    # TO AMEND?
    # add foreign key constraint
    # index on parent_id already in place
    execute <<-SQL
      WITH loop_item_ids AS (SELECT id FROM loop_items),
      loop_items_to_delete AS (
        SELECT * FROM loop_items WHERE parent_id IS NOT NULL
        EXCEPT
        SELECT loop_items.*
        FROM loop_items
        JOIN loop_items parent
        ON loop_items.parent_id = parent.id
      )
      DELETE FROM loop_items t
      USING loop_items_to_delete td
      WHERE t.id = td.id
    SQL

    add_foreign_key :loop_items,
      :loop_items, {
        column: :parent_id,
        dependent: :delete
      }

    # make loop_item_type_id NOT NULL & add foreign key constraint
    add_index :loop_items, :loop_item_type_id
    execute <<-SQL
      DELETE FROM loop_items
      WHERE id IN (
        SELECT li.id
        FROM loop_items AS li
        LEFT OUTER JOIN loop_item_types AS lit ON li.loop_item_type_id = lit.id
        WHERE lit.id IS NULL OR li.loop_item_type_id IS NULL
      )
    SQL

    change_column :loop_items,
      :loop_item_type_id, :integer, null: false
    add_foreign_key :loop_items,
      :loop_item_types, {
        column: :loop_item_type_id,
        dependent: :delete
      }

    # add foreign key constraint
    add_index :loop_items, :loop_item_name_id
    execute <<-SQL
      DELETE FROM loop_items
      WHERE id IN (
        SELECT li.id
        FROM loop_items AS li
        LEFT OUTER JOIN loop_item_names AS lin ON li.loop_item_name_id = lin.id
        WHERE lin.id IS NULL AND li.loop_item_name_id IS NOT NULL
      )
    SQL

    add_foreign_key :loop_items,
      :loop_item_names, {
        column: :loop_item_name_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE loop_items SET created_at = NOW() WHERE created_at IS NULL"
    change_column :loop_items, :created_at, :datetime, null: false
    execute "UPDATE loop_items SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :loop_items, :updated_at, :datetime, null: false
  end

  def down
    remove_foreign_key :loop_items, column: :parent_id

    remove_index :loop_items, :loop_item_type_id
    change_column :loop_items,
      :loop_item_type_id, :integer, null: true
    remove_foreign_key :loop_items, column: :loop_item_type_id

    remove_index :loop_items, :loop_item_name_id
    remove_foreign_key :loop_items, column: :loop_item_name_id

    change_column :loop_items,
      :created_at, :datetime, null: true
    change_column :loop_items,
      :updated_at, :datetime, null: true
  end
end
