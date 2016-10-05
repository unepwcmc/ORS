class AddConstraintsToRangeAnswerOptionFields < ActiveRecord::Migration
  def up
    # make range_answer_option_id NOT NULL & add foreign key constraint
    add_index :range_answer_option_fields, :range_answer_option_id
    execute <<-SQL
      DELETE FROM range_answer_option_fields
      WHERE id IN (
        SELECT raof.id
        FROM range_answer_option_fields AS raof
        LEFT OUTER JOIN range_answer_options AS rao ON raof.range_answer_option_id = rao.id
        WHERE rao.id IS NULL OR raof.range_answer_option_id IS NULL
      )
    SQL

    change_column :range_answer_option_fields,
      :range_answer_option_id, :integer, null: false
    add_foreign_key :range_answer_option_fields,
      :range_answer_options, {
        column: :range_answer_option_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE range_answer_option_fields SET language = 'en' WHERE language IS NULL"
    change_column :range_answer_option_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE range_answer_option_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :range_answer_option_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE range_answer_option_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :range_answer_option_fields, :created_at, :datetime, null: false
    execute "UPDATE range_answer_option_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :range_answer_option_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :range_answer_option_fields, :range_answer_option_id
    change_column :range_answer_option_fields,
      :range_answer_option_id, :integer, null: true
    remove_foreign_key :range_answer_option_fields, column: :range_answer_option_id

    change_column :range_answer_option_fields,
      :language, :string, null: true

    change_column :range_answer_option_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :range_answer_option_fields,
      :created_at, :datetime, null: true
    change_column :range_answer_option_fields,
      :updated_at, :datetime, null: true
  end

end
