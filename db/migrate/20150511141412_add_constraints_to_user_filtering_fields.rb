class AddConstraintsToUserFilteringFields < ActiveRecord::Migration
  def up
    # make user_id NOT NULL & add foreign key constraint
    add_index :user_filtering_fields, :user_id
    execute <<-SQL
      WITH user_filtering_fields_to_delete AS (
        SELECT * FROM user_filtering_fields
        EXCEPT
        SELECT user_filtering_fields.*
        FROM user_filtering_fields
        JOIN users
        ON user_filtering_fields.user_id = users.id
      )
      DELETE FROM user_filtering_fields t
      USING user_filtering_fields_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :user_filtering_fields,
      :user_id, :integer, null: false
    add_foreign_key :user_filtering_fields,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make filtering_field_id NOT NULL & add foreign key constraint
    add_index :user_filtering_fields, :filtering_field_id
    execute <<-SQL
      WITH user_filtering_fields_to_delete AS (
        SELECT * FROM user_filtering_fields
        EXCEPT
        SELECT user_filtering_fields.*
        FROM user_filtering_fields
        JOIN filtering_fields
        ON user_filtering_fields.filtering_field_id = filtering_fields.id
      )
      DELETE FROM user_filtering_fields t
      USING user_filtering_fields_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :user_filtering_fields,
      :filtering_field_id, :integer, null: false
    add_foreign_key :user_filtering_fields,
      :filtering_fields, {
        column: :filtering_field_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE user_filtering_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :user_filtering_fields, :created_at, :datetime, null: false
    execute "UPDATE user_filtering_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :user_filtering_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :user_filtering_fields, :user_id
    change_column :user_filtering_fields,
      :user_id, :integer, null: true
    remove_foreign_key :user_filtering_fields, column: :user_id

    remove_index :user_filtering_fields, :filtering_field_id
    change_column :user_filtering_fields,
      :filtering_field_id, :integer, null: true
    remove_foreign_key :user_filtering_fields, column: :filtering_field_id

    change_column :user_filtering_fields,
      :created_at, :datetime, null: true
    change_column :user_filtering_fields,
      :updated_at, :datetime, null: true
  end
end
