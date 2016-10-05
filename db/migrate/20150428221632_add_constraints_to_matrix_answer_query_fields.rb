class AddConstraintsToMatrixAnswerQueryFields < ActiveRecord::Migration
  def up
    # make matrix_answer_query_id NOT NULL & add foreign key constraint
    add_index :matrix_answer_query_fields, :matrix_answer_query_id
    execute <<-SQL
      DELETE FROM matrix_answer_query_fields
      WHERE id IN (
        SELECT maqf.id
        FROM matrix_answer_query_fields AS maqf
        LEFT OUTER JOIN matrix_answer_queries AS maq ON maqf.matrix_answer_query_id = maq.id
        WHERE maq.id IS NULL OR maqf.matrix_answer_query_id IS NULL
      )
    SQL

    change_column :matrix_answer_query_fields,
      :matrix_answer_query_id, :integer, null: false
    add_foreign_key :matrix_answer_query_fields,
      :matrix_answer_queries, {
        column: :matrix_answer_query_id,
        dependent: :delete,
        name: 'matrix_answer_query_fields_query_id_fk'
      }

    # make language NOT NULL
    execute "UPDATE matrix_answer_query_fields SET language = 'en' WHERE language IS NULL"
    change_column :matrix_answer_query_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE matrix_answer_query_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :matrix_answer_query_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE matrix_answer_query_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :matrix_answer_query_fields, :created_at, :datetime, null: false
    execute "UPDATE matrix_answer_query_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :matrix_answer_query_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :matrix_answer_query_fields, :matrix_answer_query_id
    change_column :matrix_answer_query_fields,
      :matrix_answer_query_id, :integer, null: true
    remove_foreign_key :matrix_answer_query_fields,
      name: 'matrix_answer_query_fields_query_id_fk'

    change_column :matrix_answer_query_fields,
      :language, :string, null: true

    change_column :matrix_answer_query_fields,
      :is_default_language, :boolean, null: true

    change_column :matrix_answer_query_fields,
      :created_at, :datetime, null: true
    change_column :matrix_answer_query_fields,
      :updated_at, :datetime, null: true
  end
end
