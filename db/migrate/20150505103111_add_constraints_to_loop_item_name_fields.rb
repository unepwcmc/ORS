class AddConstraintsToLoopItemNameFields < ActiveRecord::Migration
  def up
    # make loop_item_name_id NOT NULL & add foreign key constraint
    add_index :loop_item_name_fields, :loop_item_name_id
    execute <<-SQL
      DELETE FROM loop_item_name_fields
      WHERE id IN (
        SELECT linf.id
        FROM loop_item_name_fields AS linf
        LEFT OUTER JOIN loop_item_names AS lin ON linf.loop_item_name_id = lin.id
        WHERE lin.id IS NULL OR linf.loop_item_name_id IS NULL
      )
    SQL

    change_column :loop_item_name_fields,
      :loop_item_name_id, :integer, null: false
    add_foreign_key :loop_item_name_fields,
      :loop_item_names, {
        column: :loop_item_name_id,
        dependent: :delete
      }

    # make item_name NOT NULL
    execute "UPDATE loop_item_name_fields SET item_name = '(empty)' WHERE item_name IS NULL"
    change_column :loop_item_name_fields,
      :item_name, :text, null: false

    # make language NOT NULL
    execute "UPDATE loop_item_name_fields SET language = 'en' WHERE language IS NULL"
    change_column :loop_item_name_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE loop_item_name_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :loop_item_name_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE loop_item_name_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :loop_item_name_fields, :created_at, :datetime, null: false
    execute "UPDATE loop_item_name_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :loop_item_name_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :loop_item_name_fields, :loop_item_name_id
    change_column :loop_item_name_fields,
      :loop_item_name_id, :integer, null: true
    remove_foreign_key :loop_item_name_fields, column: :loop_item_name_id

    change_column :loop_item_name_fields,
      :item_name, :string, null: true

    change_column :loop_item_name_fields,
      :language, :string, null: true

    change_column :loop_item_name_fields,
      :is_default_language, :boolean, null: true

    change_column :loop_item_name_fields,
      :created_at, :datetime, null: true
    change_column :loop_item_name_fields,
      :updated_at, :datetime, null: true
  end

end
