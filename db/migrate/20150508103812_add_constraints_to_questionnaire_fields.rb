class AddConstraintsToQuestionnaireFields < ActiveRecord::Migration
  def up
    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :questionnaire_fields, :questionnaire_id
    execute <<-SQL
      DELETE FROM questionnaire_fields
      WHERE questionnaire_id IS NULL
      OR questionnaire_id NOT IN (
        SELECT id FROM questionnaires
      )
    SQL

    change_column :questionnaire_fields,
      :questionnaire_id, :integer, null: false
    add_foreign_key :questionnaire_fields,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE questionnaire_fields SET language = 'en' WHERE language IS NULL"
    change_column :questionnaire_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE questionnaire_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :questionnaire_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE questionnaire_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :questionnaire_fields, :created_at, :datetime, null: false
    execute "UPDATE questionnaire_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :questionnaire_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :questionnaire_fields, :questionnaire_id
    change_column :questionnaire_fields,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :questionnaire_fields, column: :questionnaire_id

    change_column :questionnaire_fields,
      :language, :string, null: true

    change_column :questionnaire_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :questionnaire_fields,
      :created_at, :datetime, null: true
    change_column :questionnaire_fields,
      :updated_at, :datetime, null: true
  end

end
