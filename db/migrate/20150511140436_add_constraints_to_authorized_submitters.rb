class AddConstraintsToAuthorizedSubmitters < ActiveRecord::Migration
  def up
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
  end

  def down
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
  end
end
