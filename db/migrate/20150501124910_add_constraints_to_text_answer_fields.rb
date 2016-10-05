class AddConstraintsToTextAnswerFields < ActiveRecord::Migration
  def up
    # make text_answer_id NOT NULL & add foreign key constraint
    add_index :text_answer_fields, :text_answer_id
    execute <<-SQL
      DELETE FROM text_answer_fields
      WHERE id IN (
        SELECT taf.id
        FROM text_answer_fields AS taf
        LEFT OUTER JOIN text_answers AS ta ON taf.text_answer_id = ta.id
        WHERE ta.id IS NULL OR taf.text_answer_id IS NULL
      )
    SQL

    change_column :text_answer_fields,
      :text_answer_id, :integer, null: false
    add_foreign_key :text_answer_fields,
      :text_answers, {
        column: :text_answer_id,
        dependent: :delete
      }

    # make rows NOT NULL
    execute "UPDATE text_answer_fields SET rows = 5 WHERE rows IS NULL"
    change_column :text_answer_fields,
      :rows, :integer, null: false, default: 5

    # make width NOT NULL
    execute "UPDATE text_answer_fields SET width=600 WHERE width IS NULL"
    change_column :text_answer_fields,
      :width, :integer, null: false, default: 600

    # make timestamps NOT NULL
    execute "UPDATE text_answer_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :text_answer_fields, :created_at, :datetime, null: false
    execute "UPDATE text_answer_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :text_answer_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :text_answer_fields, :text_answer_id
    change_column :text_answer_fields,
      :text_answer_id, :integer, null: true
    remove_foreign_key :text_answer_fields, column: :text_answer_id

    change_column :text_answer_fields,
      :rows, :integer, null: true

    change_column :text_answer_fields,
      :width, :integer, null: true

    change_column :text_answer_fields,
      :created_at, :datetime, null: true
    change_column :text_answer_fields,
      :updated_at, :datetime, null: true
  end
end
