class AddConstraintsToAuthorizedSubmitters < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_respondents_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # make user_id NOT NULL & add foreign key constraint
    add_index :authorized_submitters, :user_id
    execute <<-SQL
      WITH authorized_submitters_to_delete AS (
        SELECT * FROM authorized_submitters
        EXCEPT
        SELECT authorized_submitters.*
        FROM authorized_submitters
        JOIN users
        ON authorized_submitters.user_id = users.id
      )
      DELETE FROM authorized_submitters t
      USING authorized_submitters_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :authorized_submitters,
      :user_id, :integer, null: false
    add_foreign_key :authorized_submitters,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make questionnaire_id NOT NULL & add foreign key constraint
    add_index :authorized_submitters, :questionnaire_id
    execute <<-SQL
      WITH authorized_submitters_to_delete AS (
        SELECT * FROM authorized_submitters
        EXCEPT
        SELECT authorized_submitters.*
        FROM authorized_submitters
        JOIN questionnaires
        ON authorized_submitters.questionnaire_id = questionnaires.id
      )
      DELETE FROM authorized_submitters t
      USING authorized_submitters_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :authorized_submitters,
      :questionnaire_id, :integer, null: false
    add_foreign_key :authorized_submitters,
      :questionnaires, {
        column: :questionnaire_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE authorized_submitters SET created_at = NOW() WHERE created_at IS NULL"
    change_column :authorized_submitters, :created_at, :datetime, null: false
    execute "UPDATE authorized_submitters SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :authorized_submitters, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_respondents_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :authorized_submitters, :user_id
    change_column :authorized_submitters,
      :user_id, :integer, null: true
    remove_foreign_key :authorized_submitters, column: :user_id

    remove_index :authorized_submitters, :questionnaire_id
    change_column :authorized_submitters,
      :questionnaire_id, :integer, null: true
    remove_foreign_key :authorized_submitters, column: :questionnaire_id

    change_column :authorized_submitters,
      :created_at, :datetime, null: true
    change_column :authorized_submitters,
      :updated_at, :datetime, null: true

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def drop_view_and_dependent_views
    execute 'DROP VIEW api_respondents_view'
  end

  def create_view_and_dependent_views
    execute view_sql('20151030151237', 'api_respondents_view')
  end
end
