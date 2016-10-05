class AddConstraintsToAnswerParts < ActiveRecord::Migration
  def up
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_answers_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    # make answer_id NOT NULL & add foreign key constraint
    add_index :answer_parts, :answer_id
    execute <<-SQL
      WITH answer_ids AS (SELECT id FROM answers),
      answer_parts_to_delete AS (
        SELECT * FROM answer_parts
        EXCEPT
        SELECT answer_parts.*
        FROM answer_parts
        JOIN answer_ids ON answer_ids.id = answer_parts.answer_id
      )
      DELETE FROM answer_parts ap
      USING answer_parts_to_delete apd
      WHERE ap.id = apd.id
    SQL

    change_column :answer_parts,
      :answer_id, :integer, null: false
    add_foreign_key :answer_parts,
      :answers, {
        column: :answer_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE answer_parts SET created_at = NOW() WHERE created_at IS NULL"
    change_column :answer_parts, :created_at, :datetime, null: false
    execute "UPDATE answer_parts SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :answer_parts, :updated_at, :datetime, null: false

    # re-create the view if necessary
    create_view_and_dependent_views if re_create_view
  end

  def down
    # if API views already in place, need to drop before changing columns
    if ActiveRecord::Base.connection.table_exists? 'api_answers_view'
      drop_view_and_dependent_views
      re_create_view = true
    end

    remove_index :answer_parts, :answer_id
    change_column :answer_parts,
      :answer_id, :integer, null: true
    remove_foreign_key :answer_parts, column: :answer_id

    change_column :answer_parts, :doc_file_name, :string, null: true

    change_column :answer_parts,
      :created_at, :datetime, null: true
    change_column :answer_parts,
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
