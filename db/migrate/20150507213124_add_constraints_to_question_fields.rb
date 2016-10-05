class AddConstraintsToQuestionFields < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_questions_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # make question_id NOT NULL & add foreign key constraint
    add_index :question_fields, :question_id
    execute <<-SQL
      DELETE FROM question_fields
      WHERE id IN (
        SELECT qf.id
        FROM question_fields AS qf
        LEFT OUTER JOIN questions AS q ON qf.question_id = q.id
        WHERE q.id IS NULL OR qf.question_id IS NULL
      )
    SQL

    change_column :question_fields,
      :question_id, :integer, null: false
    add_foreign_key :question_fields,
      :questions, {
        column: :question_id,
        dependent: :delete
      }

    # make language NOT NULL
    execute "UPDATE question_fields SET language = 'en' WHERE language IS NULL"
    change_column :question_fields,
      :language, :string, null: false

    # make is_default_language NOT NULL
    execute "UPDATE question_fields SET is_default_language=FALSE WHERE is_default_language IS NULL"
    change_column :question_fields,
      :is_default_language, :boolean, null: false, default: false

    # make timestamps NOT NULL
    execute "UPDATE question_fields SET created_at = NOW() WHERE created_at IS NULL"
    change_column :question_fields, :created_at, :datetime, null: false
    execute "UPDATE question_fields SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :question_fields, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_questions_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :question_fields, :question_id
    change_column :question_fields,
      :question_id, :integer, null: true
    remove_foreign_key :question_fields, column: :question_id

    change_column :question_fields,
      :language, :string, null: true

    change_column :question_fields,
      :is_default_language, :boolean, null: true, default: false

    change_column :question_fields,
      :created_at, :datetime, null: true
    change_column :question_fields,
      :updated_at, :datetime, null: true

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_questions_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151030151237', 'api_questions_view')
    execute view_sql('20160202174508', 'api_questions_tree_view')
  end
end
