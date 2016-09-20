class AddConstraintsToQuestionExtras < ActiveRecord::Migration
  def up
    # make extra_id NOT NULL & add foreign key constraint
    add_index :question_extras, :extra_id
    execute <<-SQL
      WITH question_extras_to_delete AS (
        SELECT * FROM question_extras
        EXCEPT
        SELECT question_extras.*
        FROM question_extras
        JOIN extras
        ON question_extras.extra_id = extras.id
      )
      DELETE FROM question_extras t
      USING question_extras_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :question_extras,
      :extra_id, :integer, null: false
    add_foreign_key :question_extras,
      :extras, {
        column: :extra_id,
        dependent: :delete
      }

    # make question_id NOT NULL & add foreign key constraint
    add_index :question_extras, :question_id
    execute <<-SQL
      WITH question_extras_to_delete AS (
        SELECT * FROM question_extras
        EXCEPT
        SELECT question_extras.*
        FROM question_extras
        JOIN questions
        ON question_extras.question_id = questions.id
      )
      DELETE FROM question_extras t
      USING question_extras_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :question_extras,
      :question_id, :integer, null: false
    add_foreign_key :question_extras,
      :questions, {
        column: :question_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE question_extras SET created_at = NOW() WHERE created_at IS NULL"
    change_column :question_extras, :created_at, :datetime, null: false
    execute "UPDATE question_extras SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :question_extras, :updated_at, :datetime, null: false
  end

  def down
    remove_index :question_extras, :extra_id
    change_column :question_extras,
      :extra_id, :integer, null: true
    remove_foreign_key :question_extras, column: :extra_id

    remove_index :question_extras, :question_id
    change_column :question_extras,
      :question_id, :integer, null: true
    remove_foreign_key :question_extras, column: :question_id

    change_column :question_extras,
      :created_at, :datetime, null: true
    change_column :question_extras,
      :updated_at, :datetime, null: true
  end

end
