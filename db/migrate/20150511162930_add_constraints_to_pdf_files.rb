class AddConstraintsToPdfFiles < ActiveRecord::Migration
  def up
    # make user_id NOT NULL & add foreign key constraint
    add_index :pdf_files, :user_id
    execute <<-SQL
      WITH pdf_files_to_delete AS (
        SELECT * FROM pdf_files
        EXCEPT
        SELECT pdf_files.* FROM pdf_files
        JOIN users ON users.id = pdf_files.user_id
      )
      DELETE FROM pdf_files t
      USING pdf_files_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :pdf_files,
      :user_id, :integer, null: false
    add_foreign_key :pdf_files,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :pdf_files, :questionnaire_id
    execute <<-SQL
      WITH pdf_files_to_delete AS (
        SELECT * FROM pdf_files
        EXCEPT
        SELECT pdf_files.* FROM pdf_files
        JOIN questionnaires ON questionnaires.id = pdf_files.questionnaire_id
      )
      DELETE FROM pdf_files t
      USING pdf_files_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :pdf_files,
      :questionnaire_id, :integer, null: false
    add_foreign_key :pdf_files,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE pdf_files SET created_at = NOW() WHERE created_at IS NULL"
    change_column :pdf_files, :created_at, :datetime, null: false
    execute "UPDATE pdf_files SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :pdf_files, :updated_at, :datetime, null: false
  end

  def down
    remove_index :pdf_files, :user_id
    change_column :pdf_files,
      :user_id, :integer, null: true
    remove_foreign_key :pdf_files, column: :user_id

    remove_index :pdf_files, :questionnaire_id
    change_column :pdf_files,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :pdf_files, column: :questionnaire_id

    change_column :pdf_files,
      :created_at, :datetime, null: true
    change_column :pdf_files,
      :updated_at, :datetime, null: true
  end
end
