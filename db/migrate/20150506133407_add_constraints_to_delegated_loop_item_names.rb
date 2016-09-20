class AddConstraintsToDelegatedLoopItemNames < ActiveRecord::Migration

  def up
    # make loop_item_name_id NOT NULL & add foreign key constraint
    add_index :delegated_loop_item_names, :loop_item_name_id
    execute <<-SQL
      DELETE FROM delegated_loop_item_names
      WHERE loop_item_name_id IS NULL
      OR loop_item_name_id NOT IN (
        SELECT id FROM loop_item_names
      )
    SQL

    change_column :delegated_loop_item_names,
      :loop_item_name_id, :integer, null: false
    add_foreign_key :delegated_loop_item_names,
      :loop_item_names, {
        column: :loop_item_name_id,
        dependent: :delete
      }

    # add foreign key constraint
    add_index :delegated_loop_item_names, :delegation_section_id
    execute <<-SQL
      DELETE FROM delegated_loop_item_names
      WHERE delegation_section_id IS NOT NULL
      AND delegation_section_id NOT IN (
        SELECT id FROM delegation_sections
      )
    SQL

    add_foreign_key :delegated_loop_item_names,
      :delegation_sections, {
        column: :delegation_section_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE delegated_loop_item_names SET created_at = NOW() WHERE created_at IS NULL"
    change_column :delegated_loop_item_names, :created_at, :datetime, null: false
    execute "UPDATE delegated_loop_item_names SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :delegated_loop_item_names, :updated_at, :datetime, null: false
  end

  def down
    remove_index :delegated_loop_item_names, :loop_item_name_id
    change_column :delegated_loop_item_names,
      :loop_item_name_id, :integer, null: true
    remove_foreign_key :delegated_loop_item_names, column: :loop_item_name_id

    remove_index :delegated_loop_item_names, :delegation_section_id
    remove_foreign_key :delegated_loop_item_names, column: :delegation_section_id

    change_column :delegated_loop_item_names,
      :created_at, :datetime, null: true
    change_column :delegated_loop_item_names,
      :updated_at, :datetime, null: true
  end
end
