class AddConstraintsToRangeAnswerOptions < ActiveRecord::Migration
  def up
    # make range_answer_id NOT NULL & add foreign key constraint
    add_index :range_answer_options, :range_answer_id
    execute <<-SQL
      DELETE FROM range_answer_options
      WHERE id IN (
        SELECT rao.id
        FROM range_answer_options AS rao
        LEFT OUTER JOIN range_answers AS ra ON rao.range_answer_id = ra.id
        WHERE ra.id IS NULL OR rao.range_answer_id IS NULL
      )
    SQL

    change_column :range_answer_options,
      :range_answer_id, :integer, null: false
    add_foreign_key :range_answer_options,
      :range_answers, {
        column: :range_answer_id,
        dependent: :delete
      }

    # make sort_index NOT NULL
    execute <<-SQL
      UPDATE range_answer_options AS m
      SET sort_index = t.rank
      FROM (
        SELECT id, rank()
        OVER (PARTITION BY range_answer_id ORDER BY created_at ASC)
        FROM range_answer_options
      ) AS t
     WHERE m.id = t.id AND m.sort_index IS NULL
    SQL

    change_column :range_answer_options, :sort_index, :integer, null: false, default: 0

    # make timestamps NOT NULL
    execute "UPDATE range_answer_options SET created_at = NOW() WHERE created_at IS NULL"
    change_column :range_answer_options, :created_at, :datetime, null: false
    execute "UPDATE range_answer_options SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :range_answer_options, :updated_at, :datetime, null: false
  end

  def down
    remove_index :range_answer_options, :range_answer_id
    change_column :range_answer_options,
      :range_answer_id, :integer, null: true
    remove_foreign_key :range_answer_options, column: :range_answer_id

    change_column :range_answer_options, :sort_index, :integer, null: true

    change_column :range_answer_options,
      :created_at, :datetime, null: true
    change_column :range_answer_options,
      :updated_at, :datetime, null: true
  end
end
