class AddConstraintsToSections < ActiveRecord::Migration
  def up
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
  end

  def down
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
  end
end
