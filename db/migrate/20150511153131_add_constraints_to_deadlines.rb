class AddConstraintsToDeadlines < ActiveRecord::Migration
  def up
    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :deadlines, :questionnaire_id
    execute <<-SQL
      WITH deadlines_to_delete AS (
        SELECT * FROM deadlines
        EXCEPT
        SELECT deadlines.*
        FROM deadlines
        JOIN questionnaires
        ON deadlines.questionnaire_id = questionnaires.id
      )
      DELETE FROM deadlines t
      USING deadlines_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :deadlines,
      :questionnaire_id, :integer, null: false

    # lazy way of handling inconsistent schemas across instances
    execute 'ALTER TABLE deadlines DROP CONSTRAINT IF EXISTS deadlines_questionnaire_id_fk'
    add_foreign_key :deadlines,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    execute "UPDATE deadlines SET title = '(empty)' WHERE title IS NULL"
    change_column :deadlines, :title, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE deadlines SET created_at = NOW() WHERE created_at IS NULL"
    change_column :deadlines, :created_at, :datetime, null: false
    execute "UPDATE deadlines SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :deadlines, :updated_at, :datetime, null: false
  end

  def down
    remove_index :deadlines, :questionnaire_id
    change_column :deadlines,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :deadlines, column: :questionnaire_id

    change_column :deadlines, :title, :string, null: true

    change_column :deadlines,
      :created_at, :datetime, null: true
    change_column :deadlines,
      :updated_at, :datetime, null: true
  end
end
