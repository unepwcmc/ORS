class AddConstraintsToSectionFields < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_sections_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

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

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_sections_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

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

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_questions_looping_contexts_view'
    execute 'DROP VIEW api_sections_looping_contexts_view'
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_sections_tree_view'
    execute 'DROP VIEW api_sections_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151030151237', 'api_sections_view')
    execute view_sql('20151109160327', 'api_sections_tree_view')
    execute view_sql('20160202174508', 'api_questions_tree_view')
    execute view_sql('20151111125036', 'api_sections_looping_contexts_view')
    execute view_sql('20151111125036', 'api_questions_looping_contexts_view')
  end

end
