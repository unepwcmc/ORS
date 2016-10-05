class AddConstraintsToSections < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_sections_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # add foreign key constraint
    add_index :sections, :loop_source_id
    execute <<-SQL
      WITH sections_to_nullify AS (
        SELECT * FROM sections WHERE loop_source_id IS NOT NULL
        EXCEPT
        SELECT sections.*
        FROM sections
        JOIN loop_sources
        ON sections.loop_source_id = loop_sources.id
      )
      UPDATE sections t
      SET loop_source_id = NULL
      FROM sections_to_nullify tn
      WHERE t.id = tn.id
    SQL

    add_foreign_key :sections,
      :loop_sources, {
        column: :loop_source_id,
        dependent: :nullify
      }

    # add foreign key constraint
    # index on loop_item_type_id already in place
    execute <<-SQL
      WITH sections_to_nullify AS (
        SELECT * FROM sections WHERE loop_item_type_id IS NOT NULL
        EXCEPT
        SELECT sections.*
        FROM sections
        JOIN loop_item_types
        ON sections.loop_item_type_id = loop_item_types.id
      )
      UPDATE sections t
      SET loop_item_type_id = NULL
      FROM sections_to_nullify tn
      WHERE t.id = tn.id
    SQL

    add_foreign_key :sections,
      :loop_item_types, {
        column: :loop_item_type_id,
        dependent: :nullify
      }

    # add foreign key constraint
    add_index :sections, :depends_on_option_id
    execute <<-SQL
      WITH sections_to_nullify AS (
        SELECT * FROM sections WHERE depends_on_option_id IS NOT NULL
        EXCEPT
        SELECT sections.*
        FROM sections
        JOIN multi_answer_options
        ON sections.depends_on_option_id = multi_answer_options.id
      )
      UPDATE sections t
      SET depends_on_option_id = NULL
      FROM sections_to_nullify tn
      WHERE t.id = tn.id
    SQL

    add_foreign_key :sections,
      :multi_answer_options, {
        column: :depends_on_option_id,
        dependent: :nullify
      }

    # add foreign key constraint
    # index on depends_on_question_id already in place
    execute <<-SQL
      WITH sections_to_nullify AS (
        SELECT * FROM sections WHERE depends_on_question_id IS NOT NULL
        EXCEPT
        SELECT sections.*
        FROM sections
        JOIN questions
        ON sections.depends_on_question_id = questions.id
      )
      UPDATE sections t
      SET depends_on_question_id = NULL
      FROM sections_to_nullify tn
      WHERE t.id = tn.id
    SQL

    add_foreign_key :sections,
      :questions, {
        column: :depends_on_question_id,
        dependent: :nullify
      }

    # make section_type NOT NULL
    change_column :sections, :section_type, :integer, null: false

    # make timestamps NOT NULL
    execute "UPDATE sections SET created_at = NOW() WHERE created_at IS NULL"
    change_column :sections, :created_at, :datetime, null: false
    execute "UPDATE sections SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :sections, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_sections_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :sections, :loop_source_id
    remove_foreign_key :sections, column: :loop_source_id

    remove_foreign_key :sections, column: :loop_item_type_id

    remove_index :sections, :depends_on_option_id
    remove_foreign_key :sections, column: :depends_on_option_id

    remove_foreign_key :sections, column: :depends_on_question_id

    change_column :sections, :section_type, :integer, null: true

    change_column :sections,
      :created_at, :datetime, null: true
    change_column :sections,
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
