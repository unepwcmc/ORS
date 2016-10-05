class AddConstraintsToRangeAnswerOptionFields < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_range_answer_options_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

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

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_range_answer_options_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

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

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_answers_view'
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_range_answer_options_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151030151237', 'api_range_answer_options_view')
    execute view_sql('20160202174508', 'api_questions_tree_view')
    execute view_sql('20160203162148', 'api_answers_view')
  end
end
