class AddConstraintsToExtras < ActiveRecord::Migration
  def up
    # make loop_item_type_id NOT NULL & add foreign key constraint
    add_index :extras, :loop_item_type_id
    execute <<-SQL
      DELETE FROM extras
      WHERE id IN (
        SELECT e.id
        FROM extras AS e
        LEFT OUTER JOIN loop_item_types AS lit ON e.loop_item_type_id = lit.id
        WHERE lit.id IS NULL OR e.loop_item_type_id IS NULL
      )
    SQL

    change_column :extras,
      :loop_item_type_id, :integer, null: false
    add_foreign_key :extras,
      :loop_item_types, {
        column: :loop_item_type_id,
        dependent: :delete
      }

    # make name NOT NULL
    execute "UPDATE extras SET name = '(empty)' WHERE name IS NULL"
    change_column :extras,
      :name, :text, null: false

    # make field_type NOT NULL
    execute "UPDATE extras SET field_type = 1 WHERE field_type IS NULL"
    change_column :extras, :field_type, :integer, null: false

    # make timestamps NOT NULL
    execute "UPDATE extras SET created_at = NOW() WHERE created_at IS NULL"
    change_column :extras, :created_at, :datetime, null: false
    execute "UPDATE extras SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :extras, :updated_at, :datetime, null: false
  end

  def down
    remove_index :extras, :loop_item_type_id
    change_column :extras,
      :loop_item_type_id, :integer, null: true
    remove_foreign_key :extras, column: :loop_item_type_id

    change_column :extras,
      :name, :string, null: true

    change_column :extras, :field_type, :integer, null: true

    change_column :extras,
      :created_at, :datetime, null: true
    change_column :extras,
      :updated_at, :datetime, null: true
  end
end
