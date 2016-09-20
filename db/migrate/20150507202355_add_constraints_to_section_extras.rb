class AddConstraintsToSectionExtras < ActiveRecord::Migration
  def up
    # make extra_id NOT NULL & add foreign key constraint
    add_index :section_extras, :extra_id
    execute <<-SQL
      WITH section_extras_to_delete AS (
        SELECT * FROM section_extras
        EXCEPT
        SELECT section_extras.*
        FROM section_extras
        JOIN extras
        ON section_extras.extra_id = extras.id
      )
      DELETE FROM section_extras t
      USING section_extras_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :section_extras,
      :extra_id, :integer, null: false
    add_foreign_key :section_extras,
      :extras, {
        column: :extra_id,
        dependent: :delete
      }

    # make section_id NOT NULL & add foreign key constraint
    add_index :section_extras, :section_id
    execute <<-SQL
      WITH section_extras_to_delete AS (
        SELECT * FROM section_extras
        EXCEPT
        SELECT section_extras.*
        FROM section_extras
        JOIN sections
        ON section_extras.section_id = sections.id
      )
      DELETE FROM section_extras t
      USING section_extras_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :section_extras,
      :section_id, :integer, null: false
    add_foreign_key :section_extras,
      :sections, {
        column: :section_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE section_extras SET created_at = NOW() WHERE created_at IS NULL"
    change_column :section_extras, :created_at, :datetime, null: false
    execute "UPDATE section_extras SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :section_extras, :updated_at, :datetime, null: false
  end

  def down
    remove_index :section_extras, :extra_id
    change_column :section_extras,
      :extra_id, :integer, null: true
    remove_foreign_key :section_extras, column: :extra_id

    remove_index :section_extras, :section_id
    change_column :section_extras,
      :section_id, :integer, null: true
    remove_foreign_key :section_extras, column: :section_id

    change_column :section_extras,
      :created_at, :datetime, null: true
    change_column :section_extras,
      :updated_at, :datetime, null: true
  end
end
