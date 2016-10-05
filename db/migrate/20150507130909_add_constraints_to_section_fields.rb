class AddConstraintsToSectionFields < ActiveRecord::Migration
  def up
    # make section_id NOT NULL & add foreign key constraint
    add_index :section_fields, :section_id
    execute <<-SQL
      DELETE FROM section_fields
      WHERE id IN (
        SELECT sf.id
        FROM section_fields AS sf
        LEFT OUTER JOIN sections AS s ON sf.section_id = s.id
        WHERE s.id IS NULL OR sf.section_id IS NULL
      )
    SQL

    change_column :section_fields,
      :section_id, :integer, null: false
    add_foreign_key :section_fields,
      :sections, {
        column: :section_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE section_fields SET language = 'en' WHERE language IS NULL"
    change_column :section_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE section_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :section_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE section_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :section_fields, :created_at, :datetime, null: false
    execute "UPDATE section_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :section_fields, :updated_at, :datetime, null: false
  end

  def down
    remove_index :section_fields, :section_id
    change_column :section_fields,
      :section_id, :integer, null: true
    remove_foreign_key :section_fields, column: :section_id

    change_column :section_fields,
      :language, :string, null: true

    change_column :section_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :section_fields,
      :created_at, :datetime, null: true
    change_column :section_fields,
      :updated_at, :datetime, null: true
  end

end
