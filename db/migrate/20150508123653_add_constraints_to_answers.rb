class AddConstraintsToAnswers < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_answers_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # prepare for a long-running delete
    execute <<-SQL
      CREATE TEMP TABLE answers_to_delete AS
      SELECT answers.id FROM answers
      LEFT JOIN questions ON questions.id = answers.question_id
      WHERE questions.id IS NULL
    SQL

    add_index :answers_to_delete, :id, unique: true

    # delete dependencies first
    remove_index :answer_parts, column: :answer_id
    execute <<-SQL
      DELETE FROM answer_parts
      USING answers_to_delete a
      WHERE answer_parts.answer_id = a.id
    SQL
    add_index :answer_parts, :answer_id

    remove_index :documents, column: :answer_id
    execute <<-SQL
      DELETE FROM documents
      USING answers_to_delete a
      WHERE documents.answer_id = a.id
    SQL
    add_index :documents, :answer_id

    remove_index :answer_links, column: :answer_id
    execute <<-SQL
      DELETE FROM answer_links
      USING answers_to_delete a
      WHERE answer_links.answer_id = a.id
    SQL
    add_index :answer_links, :answer_id

    remove_index :delegate_text_answers, column: :answer_id
    execute <<-SQL
      DELETE FROM delegate_text_answers
      USING answers_to_delete a
      WHERE delegate_text_answers.answer_id = a.id
    SQL
    add_index :delegate_text_answers, :answer_id

    # add foreign key constraint
    remove_foreign_key :answers, column: :original_id
    execute <<-SQL
      DELETE FROM answers t
      USING answers_to_delete td
      WHERE t.id = td.id
    SQL

    execute "DROP TABLE answers_to_delete"

    add_foreign_key :answers, :answers, column: :original_id
    add_index :answers, :question_id

    change_column :answers,
      :question_id, :integer, null: false
    add_foreign_key :answers,
      :questions, {
        column: :question_id,
        dependent: :delete
      }

    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :answers, :questionnaire_id
    execute <<-SQL
      WITH answers_to_delete AS (
        SELECT * FROM answers
        EXCEPT
        SELECT answers.* FROM answers
        JOIN questionnaires ON questionnaires.id = answers.questionnaire_id
      )
      DELETE FROM answers t
      USING answers_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :answers,
      :questionnaire_id, :integer, null: false
    add_foreign_key :answers,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    # make user_id NOT NULL & add foreign key constraint
    add_index :answers, :user_id
    execute <<-SQL
      WITH answers_to_nullify AS (
        SELECT * FROM answers WHERE user_id IS NOT NULL
        EXCEPT
        SELECT answers.* FROM answers
        JOIN users ON users.id = answers.user_id
      ), answers_to_nullify_with_q_user AS (
        SELECT t.*, q.user_id AS q_user_id
        FROM answers_to_nullify t
        JOIN questionnaires q
        ON t.questionnaire_id = q.id
      )
      UPDATE answers t
      SET user_id = q_user_id
      FROM answers_to_nullify_with_q_user tn
      WHERE t.id = tn.id
    SQL

    change_column :answers,
      :user_id, :integer, null: false
    add_foreign_key :answers,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make user_id NOT NULL & add foreign key constraint
    add_index :answers, :last_editor_id
    execute <<-SQL
      WITH answers_to_nullify AS (
        SELECT * FROM answers WHERE last_editor_id IS NOT NULL
        EXCEPT
        SELECT answers.* FROM answers
        JOIN users ON users.id = answers.last_editor_id
      )
      UPDATE answers t
      SET last_editor_id = t.user_id
      FROM answers_to_nullify tn
      WHERE t.id = tn.id
    SQL

    add_foreign_key :answers,
      :users, {
        column: :last_editor_id,
        dependent: :nullify
      }

    # add foreign key constraint
    add_index :answers, :loop_item_id
    execute <<-SQL
      WITH answers_to_delete AS (
        SELECT * FROM answers WHERE loop_item_id IS NOT NULL
        EXCEPT
        SELECT answers.* FROM answers
        JOIN loop_items ON loop_items.id = answers.loop_item_id
      )
      DELETE FROM answers t
      USING answers_to_delete td
      WHERE t.id = td.id
    SQL

    add_foreign_key :answers,
      :loop_items, {
        column: :loop_item_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE answers SET created_at = NOW() WHERE created_at IS NULL"
    change_column :answers, :created_at, :datetime, null: false
    execute "UPDATE answers SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :answers, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_answers_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :answers, :user_id
    change_column :answers,
      :user_id, :integer, null: true
    remove_foreign_key :answers, :user_id

    remove_index :answers, :last_editor_id
    remove_foreign_key :answers, :last_editor_id

    remove_index :answers, :questionnaire_id
    change_column :answers,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :answers, :questionnaire_id

    remove_index :answers, :questionnaire_id
    change_column :answers,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :answers, :questionnaire_id

    remove_index :answers, :loop_item_id
    remove_foreign_key :answers, :loop_item_id

    change_column :answers,
      :created_at, :datetime, null: true
    change_column :answers,
      :updated_at, :datetime, null: true

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_answers_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20160203162148', 'api_answers_view')
  end
end
