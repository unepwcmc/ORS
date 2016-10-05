class AddConstraintsToFilteringFields < ActiveRecord::Migration
  def up
    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :filtering_fields, :questionnaire_id
    execute <<-SQL
      DELETE FROM filtering_fields
      WHERE id IN (
        SELECT ff.id
        FROM filtering_fields AS ff
        LEFT OUTER JOIN questionnaires AS q ON ff.questionnaire_id = q.id
        WHERE q.id IS NULL OR ff.questionnaire_id IS NULL
      )
    SQL

    change_column :filtering_fields,
      :questionnaire_id, :integer, null: false
    add_foreign_key :filtering_fields,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    execute "UPDATE filtering_fields SET name = '(empty)' WHERE name IS NULL"
    change_column :filtering_fields,
      :name, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE filtering_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :filtering_fields, :created_at, :datetime, null: false
    execute "UPDATE filtering_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :filtering_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :filtering_fields, :questionnaire_id
    change_column :filtering_fields,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :filtering_fields, column: :questionnaire_id

    change_column :filtering_fields,
      :name, :string, null: true

    change_column :filtering_fields,
      :created_at, :datetime, null: true
    change_column :filtering_fields,
      :updated_at, :datetime, null: true
  end
end
