class AddConstraintsToRankAnswerOptions < ActiveRecord::Migration
  def up
    # make rank_answer_id NOT NULL & add foreign key constraint
    add_index :rank_answer_options, :rank_answer_id
    execute <<-SQL
      DELETE FROM rank_answer_options
      WHERE rank_answer_id IS NULL
      OR rank_answer_id NOT IN (
        SELECT id FROM rank_answers
      )
    SQL

    change_column :rank_answer_options,
      :rank_answer_id, :integer, null: false
    add_foreign_key :rank_answer_options,
      :rank_answers, {
        column: :rank_answer_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE rank_answer_options SET created_at = NOW() WHERE created_at IS NULL"
    change_column :rank_answer_options, :created_at, :datetime, null: false
    execute "UPDATE rank_answer_options SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :rank_answer_options, :updated_at, :datetime, null: false
  end

  def down
    remove_index :rank_answer_options, :rank_answer_id
    change_column :rank_answer_options,
      :rank_answer_id, :integer, null: true
    remove_foreign_key :rank_answer_options, column: :rank_answer_id

    change_column :rank_answer_options,
      :created_at, :datetime, null: true
    change_column :rank_answer_options,
      :updated_at, :datetime, null: true
  end
end
