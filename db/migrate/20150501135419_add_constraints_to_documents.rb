class AddConstraintsToDocuments < ActiveRecord::Migration
  def up
    # make answer_id NOT NULL & add foreign key constraint
    # index on answer_id already in place
    execute <<-SQL
      WITH answer_ids AS (SELECT id FROM answers),
      documents_to_delete AS (
        SELECT * FROM documents
        EXCEPT
        SELECT documents.*
        FROM documents
        JOIN answer_ids ON answer_ids.id = documents.answer_id
      )
      DELETE FROM documents t
      USING documents_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :documents,
      :answer_id, :integer, null: false
    add_foreign_key :documents,
      :answers, {
        column: :answer_id,
        dependent: :delete
      }

    # make doc_file_name NOT NULL
    execute "DELETE FROM documents WHERE doc_file_name IS NULL"
    change_column :documents, :doc_file_name, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE documents SET created_at = NOW() WHERE created_at IS NULL"
    change_column :documents, :created_at, :datetime, null: false
    execute "UPDATE documents SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :documents, :updated_at, :datetime, null: false
  end

  def down
    change_column :documents,
      :answer_id, :integer, null: true
    remove_foreign_key :documents, column: :answer_id

    change_column :documents, :doc_file_name, :string, null: true

    change_column :documents,
      :created_at, :datetime, null: true
    change_column :documents,
      :updated_at, :datetime, null: true
  end
end
