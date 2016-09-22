class AddConstraintsToMatrixAnswerOptionFields < ActiveRecord::Migration
  def up
    # make matrix_answer_option_id NOT NULL & add foreign key constraint
    add_index :matrix_answer_option_fields, :matrix_answer_option_id
    execute <<-SQL
      DELETE FROM matrix_answer_option_fields
      WHERE matrix_answer_option_id IS NULL
      OR matrix_answer_option_id NOT IN (
        SELECT id FROM matrix_answer_options
      )
    SQL

    change_column :matrix_answer_option_fields,
      :matrix_answer_option_id, :integer, null: false
    add_foreign_key :matrix_answer_option_fields,
      :matrix_answer_options, {
        column: :matrix_answer_option_id,
        dependent: :delete,
        name: 'matrix_answer_option_fields_option_id_fk'
      }

    # make language NOT NULL
    execute "UPDATE matrix_answer_option_fields SET language = 'en' WHERE language IS NULL"
    change_column :matrix_answer_option_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE matrix_answer_option_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :matrix_answer_option_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE matrix_answer_option_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :matrix_answer_option_fields, :created_at, :datetime, null: false
    execute "UPDATE matrix_answer_option_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :matrix_answer_option_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :matrix_answer_option_fields, :matrix_answer_option_id
    change_column :matrix_answer_option_fields,
      :matrix_answer_option_id, :integer, null: true
    remove_foreign_key :matrix_answer_option_fields,
      name: 'matrix_answer_option_fields_option_id_fk'

    change_column :matrix_answer_option_fields,
      :language, :string, null: true

    change_column :matrix_answer_option_fields,
      :is_default_language, :boolean, null: true

    change_column :matrix_answer_option_fields,
      :created_at, :datetime, null: true
    change_column :matrix_answer_option_fields,
      :updated_at, :datetime, null: true
  end
end
