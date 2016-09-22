class AddConstraintsToItemExtras < ActiveRecord::Migration
  def up
    # make loop_item_name_id NOT NULL & add foreign key constraint
    add_index :item_extras, :loop_item_name_id
    execute <<-SQL
      DELETE FROM item_extras
      WHERE loop_item_name_id IS NULL
      OR loop_item_name_id NOT IN (
        SELECT id FROM loop_item_names
      )
    SQL

    change_column :item_extras,
      :loop_item_name_id, :integer, null: false
    add_foreign_key :item_extras,
      :loop_item_names, {
        column: :loop_item_name_id,
        dependent: :delete
      }

    # make extra_id NOT NULL & add foreign key constraint
    add_index :item_extras, :extra_id
    execute <<-SQL
      DELETE FROM item_extras
      WHERE extra_id IS NULL
      OR extra_id NOT IN (
        SELECT id FROM extras
      )
    SQL

    change_column :item_extras,
      :extra_id, :integer, null: false
    add_foreign_key :item_extras,
      :extras, {
        column: :extra_id,
        dependent: :delete,
        name: 'item_extras_extra_id_fk'
      }

    # make timestamps NOT NULL
    execute "UPDATE item_extras SET created_at = NOW() WHERE created_at IS NULL"
    change_column :item_extras, :created_at, :datetime, null: false
    execute "UPDATE item_extras SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :item_extras, :updated_at, :datetime, null: false
  end

  def down
    remove_index :item_extras, :loop_item_name_id
    change_column :item_extras,
      :loop_item_name_id, :integer, null: true
    remove_foreign_key :item_extras, column: :loop_item_name_id

    remove_index :item_extras, :extra_id
    change_column :item_extras,
      :extra_id, :integer, null: true
    remove_foreign_key :item_extras, column: :extra_id

    change_column :item_extras,
      :created_at, :datetime, null: true
    change_column :item_extras,
      :updated_at, :datetime, null: true
  end

end
