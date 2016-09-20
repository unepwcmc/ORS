class AddConstraintsToItemExtraFields < ActiveRecord::Migration
  def up
    # make item_extra_id NOT NULL & add foreign key constraint
    add_index :item_extra_fields, :item_extra_id
    execute <<-SQL
      DELETE FROM item_extra_fields
      WHERE item_extra_id IS NULL
      OR item_extra_id NOT IN (
        SELECT id FROM item_extras
      )
    SQL

    change_column :item_extra_fields,
      :item_extra_id, :integer, null: false
    add_foreign_key :item_extra_fields,
      :item_extras, {
        column: :item_extra_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE item_extra_fields SET language = 'en' WHERE language IS NULL"
    change_column :item_extra_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE item_extra_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :item_extra_fields,
      :is_default_language, :boolean, null: false, default: false

    # make value NOT NULL
    execute "UPDATE item_extra_fields SET value = '(empty)' WHERE value IS NULL"
    change_column :item_extra_fields,
      :value, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE item_extra_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :item_extra_fields, :created_at, :datetime, null: false
    execute "UPDATE item_extra_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :item_extra_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :item_extra_fields, :item_extra_id
    change_column :item_extra_fields,
      :item_extra_id, :integer, null: true
    remove_foreign_key :item_extra_fields, column: :item_extra_id

    change_column :item_extra_fields,
      :language, :string, null: true

    change_column :item_extra_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :item_extra_fields,
      :value, :string, null: true

    change_column :item_extra_fields,
      :created_at, :datetime, null: true
    change_column :item_extra_fields,
      :updated_at, :datetime, null: true
  end
end
