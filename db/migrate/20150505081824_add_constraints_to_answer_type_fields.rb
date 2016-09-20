class AddConstraintsToAnswerTypeFields < ActiveRecord::Migration
  def up
    # make language NOT NULL
    execute "UPDATE answer_type_fields SET language = 'en' WHERE language IS NULL"
    change_column :answer_type_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE answer_type_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :answer_type_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE answer_type_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :answer_type_fields, :created_at, :datetime, null: false
    execute "UPDATE answer_type_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :answer_type_fields, :updated_at, :datetime, null: false
  end

  def down
    change_column :answer_type_fields,
      :language, :string, null: true

    change_column :answer_type_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :answer_type_fields,
      :created_at, :datetime, null: true
    change_column :answer_type_fields,
      :updated_at, :datetime, null: true
  end
end
