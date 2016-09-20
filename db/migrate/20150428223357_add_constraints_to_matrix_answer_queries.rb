class AddConstraintsToMatrixAnswerQueries < ActiveRecord::Migration
  def up
    # make matrix_answer_id NOT NULL & add foreign key constraint
    add_index :matrix_answer_queries, :matrix_answer_id
    execute <<-SQL
      DELETE FROM matrix_answer_queries
      WHERE matrix_answer_id IS NULL
      OR matrix_answer_id NOT IN (
        SELECT id FROM matrix_answers
      )
    SQL

    change_column :matrix_answer_queries,
      :matrix_answer_id, :integer, null: false
    add_foreign_key :matrix_answer_queries,
      :matrix_answers, {
        column: :matrix_answer_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE matrix_answer_queries SET created_at = NOW() WHERE created_at IS NULL"
    change_column :matrix_answer_queries, :created_at, :datetime, null: false
    execute "UPDATE matrix_answer_queries SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :matrix_answer_queries, :updated_at, :datetime, null: false
  end

  def down
    remove_index :matrix_answer_queries, :matrix_answer_id
    change_column :matrix_answer_queries,
      :matrix_answer_id, :integer, null: true
    remove_foreign_key :matrix_answer_queries, column: :matrix_answer_id

    change_column :matrix_answer_queries,
      :created_at, :datetime, null: true
    change_column :matrix_answer_queries,
      :updated_at, :datetime, null: true
  end
end
