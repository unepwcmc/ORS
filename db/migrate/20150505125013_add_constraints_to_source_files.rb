class AddConstraintsToSourceFiles < ActiveRecord::Migration
  def up
    # add foreign key constraint
    add_index :source_files, :loop_source_id
    execute <<-SQL
      DELETE FROM source_files
      WHERE id IN (
        SELECT sf.id
        FROM source_files AS sf
        LEFT OUTER JOIN loop_sources AS ls ON sf.loop_source_id = ls.id
        WHERE ls.id IS NULL OR sf.loop_source_id IS NULL
      )
    SQL

    change_column :source_files,
      :loop_source_id, :integer, null: false
    add_foreign_key :source_files,
      :loop_sources, {
        column: :loop_source_id,
        dependent: :delete
      }

    execute "UPDATE source_files SET source_file_name = '(empty)' WHERE source_file_name IS NULL"
    change_column :source_files,
      :source_file_name, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE source_files SET created_at = NOW() WHERE created_at IS NULL"
    change_column :source_files, :created_at, :datetime, null: false
    execute "UPDATE source_files SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :source_files, :updated_at, :datetime, null: false
  end

  def down
    remove_index :source_files, :loop_source_id
    change_column :source_files,
      :loop_source_id, :integer, null: true
    remove_foreign_key :source_files, column: :loop_source_id

    change_column :source_files,
      :source_file_name, :string, null: true

    change_column :source_files,
      :created_at, :datetime, null: true
    change_column :source_files,
      :updated_at, :datetime, null: true
  end
end
