class AddConstraintsToLoopItemNameFields < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_sections_looping_contexts_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # make loop_item_name_id NOT NULL & add foreign key constraint
    add_index :loop_item_name_fields, :loop_item_name_id
    execute <<-SQL
      DELETE FROM loop_item_name_fields
      WHERE id IN (
        SELECT linf.id
        FROM loop_item_name_fields AS linf
        LEFT OUTER JOIN loop_item_names AS lin ON linf.loop_item_name_id = lin.id
        WHERE lin.id IS NULL OR linf.loop_item_name_id IS NULL
      )
    SQL

    change_column :loop_item_name_fields,
      :loop_item_name_id, :integer, null: false
    add_foreign_key :loop_item_name_fields,
      :loop_item_names, {
        column: :loop_item_name_id,
        dependent: :delete
      }

    # make item_name NOT NULL
    execute "UPDATE loop_item_name_fields SET item_name = '(empty)' WHERE item_name IS NULL"
    change_column :loop_item_name_fields,
      :item_name, :text, null: false

    # make language NOT NULL
    execute "UPDATE loop_item_name_fields SET language = 'en' WHERE language IS NULL"
    change_column :loop_item_name_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE loop_item_name_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :loop_item_name_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE loop_item_name_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :loop_item_name_fields, :created_at, :datetime, null: false
    execute "UPDATE loop_item_name_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :loop_item_name_fields, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_sections_looping_contexts_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :loop_item_name_fields, :loop_item_name_id
    change_column :loop_item_name_fields,
      :loop_item_name_id, :integer, null: true
    remove_foreign_key :loop_item_name_fields, column: :loop_item_name_id

    change_column :loop_item_name_fields,
      :item_name, :string, null: true

    change_column :loop_item_name_fields,
      :language, :string, null: true

    change_column :loop_item_name_fields,
      :is_default_language, :boolean, null: true

    change_column :loop_item_name_fields,
      :created_at, :datetime, null: true
    change_column :loop_item_name_fields,
      :updated_at, :datetime, null: true

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_questions_looping_contexts_view'
    execute 'DROP VIEW api_sections_looping_contexts_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151111125036', 'api_sections_looping_contexts_view')
    execute view_sql('20151111125036', 'api_questions_looping_contexts_view')
  end
end
