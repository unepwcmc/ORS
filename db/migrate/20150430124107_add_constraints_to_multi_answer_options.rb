class AddConstraintsToMultiAnswerOptions < ActiveRecord::Migration
  def up
    # make multi_answer_id NOT NULL & add foreign key constraint
    add_index :multi_answer_options, :multi_answer_id
    execute <<-SQL
      DELETE FROM multi_answer_options
      WHERE id IN (
        SELECT mao.id
        FROM multi_answer_options AS mao
        LEFT OUTER JOIN multi_answers AS ma ON mao.multi_answer_id = ma.id
        WHERE ma.id IS NULL OR mao.multi_answer_id IS NULL
      )
    SQL

    change_column :multi_answer_options,
      :multi_answer_id, :integer, null: false
    add_foreign_key :multi_answer_options,
      :multi_answers, {
        column: :multi_answer_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE multi_answer_options SET created_at = NOW() WHERE created_at IS NULL"
    change_column :multi_answer_options, :created_at, :datetime, null: false
    execute "UPDATE multi_answer_options SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :multi_answer_options, :updated_at, :datetime, null: false
  end

  def down
    remove_index :multi_answer_options, :multi_answer_id
    change_column :multi_answer_options,
      :multi_answer_id, :integer, null: true
    remove_foreign_key :multi_answer_options, column: :multi_answer_id

    change_column :multi_answer_options,
      :created_at, :datetime, null: true
    change_column :multi_answer_options,
      :updated_at, :datetime, null: true
  end
end
