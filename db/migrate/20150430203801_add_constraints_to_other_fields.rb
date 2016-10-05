class AddConstraintsToOtherFields < ActiveRecord::Migration
  def up
    # make multi_answer_id NOT NULL & add foreign key constraint
    add_index :other_fields, :multi_answer_id
    execute <<-SQL
      DELETE FROM other_fields
      WHERE id IN (
        SELECT of.id
        FROM other_fields AS of
        LEFT OUTER JOIN multi_answers AS ma ON of.multi_answer_id = ma.id
        WHERE ma.id IS NULL OR of.multi_answer_id IS NULL
      )
    SQL

    change_column :other_fields,
      :multi_answer_id, :integer, null: false
    add_foreign_key :other_fields,
      :multi_answers, {
        column: :multi_answer_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE other_fields SET language = 'en' WHERE language IS NULL"
    change_column :other_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE other_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :other_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE other_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :other_fields, :created_at, :datetime, null: false
    execute "UPDATE other_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :other_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :other_fields, :multi_answer_id
    change_column :other_fields,
      :multi_answer_id, :integer, null: true
    remove_foreign_key :other_fields, column: :multi_answer_id

    change_column :multi_answer_option_fields,
      :language, :string, null: true

    change_column :multi_answer_option_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :other_fields,
      :created_at, :datetime, null: true
    change_column :other_fields,
      :updated_at, :datetime, null: true
  end
end
