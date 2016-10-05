class AddConstraintsToQuestions < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_questions_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # these columns are empty in all instances of ORS & not referenced in the code
    remove_column :questions, :type
    remove_column :questions, :ordering
    remove_column :questions, :number

    # make section_id NOT NULL & add foreign key constraint
    add_index :questions, :section_id
    execute <<-SQL
      WITH questions_to_delete AS (
        SELECT * FROM questions
        EXCEPT
        SELECT questions.* FROM questions
        JOIN sections ON sections.id = questions.section_id
      )
      DELETE FROM questions t
      USING questions_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :questions,
      :section_id, :integer, null: false
    add_foreign_key :questions,
      :sections, {
        column: :section_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE questions SET created_at = NOW() WHERE created_at IS NULL"
    change_column :questions, :created_at, :datetime, null: false
    execute "UPDATE questions SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :questions, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_questions_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    add_column :questions, :type, :integer
    add_column :questions, :ordering, :integer
    add_column :questions, :number, :integer

    remove_index :questions, :section_id
    change_column :questions,
      :section_id, :integer, null: true
    remove_foreign_key :questions, column: :section_id

    change_column :questions,
      :created_at, :datetime, null: true
    change_column :questions,
      :updated_at, :datetime, null: true

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_questions_looping_contexts_view'
    execute 'DROP VIEW api_questions_tree_view'
    execute 'DROP VIEW api_questions_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151030151237', 'api_questions_view')
    execute view_sql('20160202174508', 'api_questions_tree_view')
    execute view_sql('20151111125036', 'api_questions_looping_contexts_view')
  end
end
