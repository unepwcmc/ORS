class AddConstraintsToMatrixAnswerOptions < ActiveRecord::Migration
  def up
    # make matrix_answer_id NOT NULL & add foreign key constraint
    add_index :matrix_answer_options, :matrix_answer_id
    execute <<-SQL
      DELETE FROM matrix_answer_options
      WHERE id IN (
        SELECT mao.id
        FROM matrix_answer_options AS mao
        LEFT OUTER JOIN matrix_answers AS ma ON mao.matrix_answer_id = ma.id
        WHERE ma.id IS NULL OR mao.matrix_answer_id IS NULL
      )
    SQL

    change_column :matrix_answer_options,
      :matrix_answer_id, :integer, null: false
    add_foreign_key :matrix_answer_options,
      :matrix_answers, {
        column: :matrix_answer_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE matrix_answer_options SET created_at = NOW() WHERE created_at IS NULL"
    change_column :matrix_answer_options, :created_at, :datetime, null: false
    execute "UPDATE matrix_answer_options SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :matrix_answer_options, :updated_at, :datetime, null: false
  end

  def down
    remove_index :matrix_answer_options, :matrix_answer_id
    change_column :matrix_answer_options,
      :matrix_answer_id, :integer, null: true
    remove_foreign_key :matrix_answer_options, column: :matrix_answer_id

    change_column :matrix_answer_options,
      :created_at, :datetime, null: true
    change_column :matrix_answer_options,
      :updated_at, :datetime, null: true
  end
end
