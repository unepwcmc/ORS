class AddConstraintsToLoopSources < ActiveRecord::Migration
  def up
    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :loop_sources, :questionnaire_id
    execute <<-SQL
      DELETE FROM loop_sources
      WHERE id IN (
        SELECT ls.id
        FROM loop_sources AS ls
        LEFT OUTER JOIN questionnaires AS q ON ls.questionnaire_id = q.id
        WHERE q.id IS NULL OR ls.questionnaire_id IS NULL
      )
    SQL

    change_column :loop_sources,
      :questionnaire_id, :integer, null: false
    add_foreign_key :loop_sources,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    execute "UPDATE loop_sources SET name = '(empty)' WHERE name IS NULL"
    change_column :loop_sources,
      :name, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE loop_sources SET created_at = NOW() WHERE created_at IS NULL"
    change_column :loop_sources, :created_at, :datetime, null: false
    execute "UPDATE loop_sources SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :loop_sources, :updated_at, :datetime, null: false
  end

  def down
    remove_index :loop_sources, :questionnaire_id
    change_column :loop_sources,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :loop_sources, column: :questionnaire_id

    change_column :loop_sources,
      :name, :string, null: true

    change_column :loop_sources,
      :created_at, :datetime, null: true
    change_column :loop_sources,
      :updated_at, :datetime, null: true
  end
end
