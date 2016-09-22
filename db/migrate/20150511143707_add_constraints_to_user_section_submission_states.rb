class AddConstraintsToUserSectionSubmissionStates < ActiveRecord::Migration
  def up
    # make user_id NOT NULL & add foreign key constraint
    add_index :user_section_submission_states, :user_id
    execute <<-SQL
      WITH user_section_submission_states_to_delete AS (
        SELECT * FROM user_section_submission_states
        EXCEPT
        SELECT user_section_submission_states.*
        FROM user_section_submission_states
        JOIN users
        ON user_section_submission_states.user_id = users.id
      )
      DELETE FROM user_section_submission_states t
      USING user_section_submission_states_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :user_section_submission_states,
      :user_id, :integer, null: false
    add_foreign_key :user_section_submission_states,
      :users, {
        column: :user_id,
        dependent: :delete
      }

    # make section_id NOT NULL & add foreign key constraint
    add_index :user_section_submission_states, :section_id
    execute <<-SQL
      WITH user_section_submission_states_to_delete AS (
        SELECT * FROM user_section_submission_states
        EXCEPT
        SELECT user_section_submission_states.*
        FROM user_section_submission_states
        JOIN sections
        ON user_section_submission_states.section_id = sections.id
      )
      DELETE FROM user_section_submission_states t
      USING user_section_submission_states_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :user_section_submission_states,
      :section_id, :integer, null: false
    add_foreign_key :user_section_submission_states,
      :sections, {
        column: :section_id,
        dependent: :delete
      }

    # add foreign key constraint
    add_index :user_section_submission_states, :loop_item_id
    execute <<-SQL
      WITH user_section_submission_states_to_delete AS (
        SELECT * FROM user_section_submission_states WHERE loop_item_id IS NOT NULL
        EXCEPT
        SELECT user_section_submission_states.*
        FROM user_section_submission_states
        JOIN loop_items
        ON user_section_submission_states.loop_item_id = loop_items.id
      )
      DELETE FROM user_section_submission_states t
      USING user_section_submission_states_to_delete td
      WHERE t.id = td.id
    SQL

    add_foreign_key :user_section_submission_states,
      :loop_items, {
        column: :loop_item_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE user_section_submission_states SET created_at = NOW() WHERE created_at IS NULL"
    change_column :user_section_submission_states, :created_at, :datetime, null: false
    execute "UPDATE user_section_submission_states SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :user_section_submission_states, :updated_at, :datetime, null: false
  end

  def down
    remove_index :user_section_submission_states, :user_id
    change_column :user_section_submission_states,
      :user_id, :integer, null: true
    remove_foreign_key :user_section_submission_states, column: :user_id

    remove_index :user_section_submission_states, :section_id
    change_column :user_section_submission_states,
      :section_id, :integer, null: true
    remove_foreign_key :user_section_submission_states, column: :section_id

    remove_index :user_section_submission_states, :loop_item_id
    remove_foreign_key :user_section_submission_states, column: :loop_item_id

    change_column :user_section_submission_states,
      :created_at, :datetime, null: true
    change_column :user_section_submission_states,
      :updated_at, :datetime, null: true
  end
end
