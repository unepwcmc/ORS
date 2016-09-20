class AddConstraintsToQuestionLoopTypes < ActiveRecord::Migration
  def up
    # make loop_item_type_id NOT NULL & add foreign key constraint
    add_index :question_loop_types, :loop_item_type_id
    execute <<-SQL
      WITH question_loop_types_to_delete AS (
        SELECT * FROM question_loop_types
        EXCEPT
        SELECT question_loop_types.*
        FROM question_loop_types
        JOIN loop_item_types
        ON question_loop_types.loop_item_type_id = loop_item_types.id
      )
      DELETE FROM question_loop_types t
      USING question_loop_types_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :question_loop_types,
      :loop_item_type_id, :integer, null: false
    add_foreign_key :question_loop_types,
      :loop_item_types, {
        column: :loop_item_type_id,
        dependent: :delete
      }

    # make question_id NOT NULL & add foreign key constraint
    add_index :question_loop_types, :question_id
    execute <<-SQL
      WITH question_loop_types_to_delete AS (
        SELECT * FROM question_loop_types
        EXCEPT
        SELECT question_loop_types.*
        FROM question_loop_types
        JOIN questions
        ON question_loop_types.question_id = questions.id
      )
      DELETE FROM question_loop_types t
      USING question_loop_types_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :question_loop_types,
      :question_id, :integer, null: false
    add_foreign_key :question_loop_types,
      :questions, {
        column: :question_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE question_loop_types SET created_at = NOW() WHERE created_at IS NULL"
    change_column :question_loop_types, :created_at, :datetime, null: false
    execute "UPDATE question_loop_types SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :question_loop_types, :updated_at, :datetime, null: false
  end

  def down
    remove_index :question_loop_types, :loop_item_type_id
    change_column :question_loop_types,
      :loop_item_type_id, :integer, null: true
    remove_foreign_key :question_loop_types, column: :loop_item_type_id

    remove_index :question_loop_types, :question_id
    change_column :question_loop_types,
      :question_id, :integer, null: true
    remove_foreign_key :question_loop_types, column: :question_id

    change_column :question_loop_types,
      :created_at, :datetime, null: true
    change_column :question_loop_types,
      :updated_at, :datetime, null: true
  end
end
