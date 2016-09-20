class AddConstraintsToQuestionnaires < ActiveRecord::Migration
  def up
    best_effort_admin_user = User.administrators.find(
      :first, order: 'last_login_at DESC'
    )

    # if none found, create one
    unless best_effort_admin_user
      best_effort_admin_user = User.new(
        first_name: 'SYSTEM', last_name: 'SYSTEM', email: 'SYSTEM',
        password: password = SecureRandom.hex.first(8),
        password_confirmation: password,
        single_access_token: SecureRandom.hex.first(32),
        perishable_token: SecureRandom.hex.first(32)
      )
      best_effort_admin_user.save(validate: false)
    end

    # make user_id NOT NULL & add foreign key constraint
    add_index :questionnaires, :user_id
    execute <<-SQL
      WITH questionnaires_to_nullify AS (
        SELECT * FROM questionnaires WHERE user_id IS NOT NULL
        EXCEPT
        SELECT questionnaires.* FROM questionnaires
        JOIN users ON users.id = questionnaires.user_id
      )
      UPDATE questionnaires t
      SET user_id = #{best_effort_admin_user.id}
      FROM questionnaires_to_nullify tn
      WHERE t.id = tn.id
    SQL

    change_column :questionnaires,
      :user_id, :integer, null: false
    add_foreign_key :questionnaires,
      :users, {
        column: :user_id,
        dependent: :restrict
      }

    # make user_id NOT NULL & add foreign key constraint
    add_index :questionnaires, :last_editor_id
    execute <<-SQL
      WITH questionnaires_to_nullify AS (
        SELECT * FROM questionnaires WHERE user_id IS NOT NULL
        EXCEPT
        SELECT questionnaires.* FROM questionnaires
        JOIN users ON users.id = questionnaires.last_editor_id
      )
      UPDATE questionnaires t
      SET last_editor_id = t.user_id
      FROM questionnaires_to_nullify tn
      WHERE t.id = tn.id
    SQL

    add_foreign_key :questionnaires,
      :users, {
        column: :last_editor_id,
        dependent: :nullify
      }

    # make timestamps NOT NULL
    execute "UPDATE questionnaires SET created_at = NOW() WHERE created_at IS NULL"
    change_column :questionnaires, :created_at, :datetime, null: false
    execute "UPDATE questionnaires SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :questionnaires, :updated_at, :datetime, null: false
  end

  def down
    remove_index :questionnaires, :user_id
    change_column :questionnaires,
      :user_id, :integer, null: true
    remove_foreign_key :questionnaires, column: :user_id

    remove_index :questionnaires, :last_editor_id
    remove_foreign_key :questionnaires, column: :last_editor_id

    change_column :questionnaires,
      :created_at, :datetime, null: true
    change_column :questionnaires,
      :updated_at, :datetime, null: true
  end
end
