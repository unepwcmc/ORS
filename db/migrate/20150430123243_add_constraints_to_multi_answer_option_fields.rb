class AddConstraintsToMultiAnswerOptionFields < ActiveRecord::Migration
  def up
    # make multi_answer_option_id NOT NULL & add foreign key constraint
    add_index :multi_answer_option_fields, :multi_answer_option_id
    execute <<-SQL
      DELETE FROM multi_answer_option_fields
      WHERE multi_answer_option_id IS NULL
      OR multi_answer_option_id NOT IN (
        SELECT id FROM multi_answer_options
      )
    SQL

    change_column :multi_answer_option_fields,
      :multi_answer_option_id, :integer, null: false
    add_foreign_key :multi_answer_option_fields,
      :multi_answer_options, {
        column: :multi_answer_option_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE multi_answer_option_fields SET language = 'en' WHERE language IS NULL"
    change_column :multi_answer_option_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE multi_answer_option_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :multi_answer_option_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE multi_answer_option_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :multi_answer_option_fields, :created_at, :datetime, null: false
    execute "UPDATE multi_answer_option_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :multi_answer_option_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :multi_answer_option_fields, :multi_answer_option_id
    change_column :multi_answer_option_fields,
      :multi_answer_option_id, :integer, null: true
    remove_foreign_key :multi_answer_option_fields, column: :multi_answer_option_id

    change_column :multi_answer_option_fields,
      :language, :string, null: true

    change_column :multi_answer_option_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :multi_answer_option_fields,
      :created_at, :datetime, null: true
    change_column :multi_answer_option_fields,
      :updated_at, :datetime, null: true
  end
end
