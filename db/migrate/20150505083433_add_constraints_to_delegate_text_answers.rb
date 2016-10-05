class AddConstraintsToDelegateTextAnswers < ActiveRecord::Migration
  def up
    # make answer_id NOT NULL
    add_index :delegate_text_answers, :answer_id
    execute <<-SQL
      DELETE FROM delegate_text_answers
      WHERE id IN (
        SELECT dta.id
        FROM delegate_text_answers AS dta
        LEFT OUTER JOIN answers AS a ON dta.answer_id = a.id
        WHERE a.id IS NULL OR dta.answer_id IS NULL
      )
    SQL

    change_column :delegate_text_answers,
      :answer_id, :integer, null: false

    # make user_id NOT NULL
    add_index :delegate_text_answers, :user_id
    execute <<-SQL
      DELETE FROM delegate_text_answers
      WHERE user_id IS NULL
      OR user_id NOT IN (
        SELECT id FROM users
      )
    SQL

    change_column :delegate_text_answers,
      :user_id, :integer, null: false
  end

  def down
    remove_index :delegate_text_answers, :answer_id
    change_column :delegate_text_answers,
      :answer_id, :integer, null: true
    remove_index :delegate_text_answers, :user_id
    change_column :delegate_text_answers,
      :user_id, :integer, null: true

  end
end
