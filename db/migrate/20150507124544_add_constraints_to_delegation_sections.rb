class AddConstraintsToDelegationSections < ActiveRecord::Migration
  def up
    # make delegation_id NOT NULL & add foreign key constraint
    add_index :delegation_sections, :delegation_id
    execute <<-SQL
      WITH delegation_sections_to_delete AS (
        SELECT * FROM delegation_sections
        EXCEPT
        SELECT delegation_sections.*
        FROM delegation_sections
        JOIN delegations
        ON delegation_sections.delegation_id = delegations.id
      )
      DELETE FROM delegation_sections t
      USING delegation_sections_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :delegation_sections,
      :delegation_id, :integer, null: false
    add_foreign_key :delegation_sections,
      :delegations, {
        column: :delegation_id,
        dependent: :delete
      }

    # make section_id NOT NULL & add foreign key constraint
    add_index :delegation_sections, :section_id
    execute <<-SQL
      WITH delegation_sections_to_delete AS (
        SELECT * FROM delegation_sections
        EXCEPT
        SELECT delegation_sections.*
        FROM delegation_sections
        JOIN sections
        ON delegation_sections.section_id = sections.id
      )
      DELETE FROM delegation_sections t
      USING delegation_sections_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :delegation_sections,
      :section_id, :integer, null: false
    add_foreign_key :delegation_sections,
      :sections, {
        column: :section_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE delegation_sections SET created_at = NOW() WHERE created_at IS NULL"
    change_column :delegation_sections, :created_at, :datetime, null: false
    execute "UPDATE delegation_sections SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :delegation_sections, :updated_at, :datetime, null: false
  end

  def down
    remove_index :delegation_sections, :delegation_id
    change_column :delegation_sections,
      :delegation_id, :integer, null: true
    remove_foreign_key :delegation_sections, column: :delegation_id

    remove_index :delegation_sections, :section_id
    change_column :delegation_sections,
      :section_id, :integer, null: true
    remove_foreign_key :delegation_sections, column: :section_id

    change_column :delegation_sections,
      :created_at, :datetime, null: true
    change_column :delegation_sections,
      :updated_at, :datetime, null: true
  end
end
