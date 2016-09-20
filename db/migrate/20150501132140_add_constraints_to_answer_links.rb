class AddConstraintsToAnswerLinks < ActiveRecord::Migration
  def up
    # make answer_id NOT NULL & add foreign key constraint
    add_index :answer_links, :answer_id
    execute <<-SQL
      WITH answer_ids AS (SELECT id FROM answers),
      answer_links_to_delete AS (
        SELECT * FROM answer_links
        EXCEPT
        SELECT answer_links.*
        FROM answer_links
        JOIN answer_ids ON answer_ids.id = answer_links.answer_id
      )
      DELETE FROM answer_links t
      USING answer_links_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :answer_links,
      :answer_id, :integer, null: false
    add_foreign_key :answer_links,
      :answers, {
        column: :answer_id,
        dependent: :delete
      }

    # make url NOT NULL
    execute "DELETE FROM answer_links WHERE url IS NULL AND title IS NULL"
    execute "UPDATE answer_links SET url = '' WHERE url IS NULL AND title IS NOT NULL"
    change_column :answer_links, :url, :text, null: false

    # make timestamps NOT NULL
    execute "UPDATE answer_links SET created_at = NOW() WHERE created_at IS NULL"
    change_column :answer_links, :created_at, :datetime, null: false
    execute "UPDATE answer_links SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :answer_links, :updated_at, :datetime, null: false
  end

  def down
    remove_index :answer_links, :answer_id
    change_column :answer_links,
      :answer_id, :integer, null: true
    remove_foreign_key :answer_links, column: :answer_id

    change_column :answer_links, :url, :text, null: true

    change_column :answer_links,
      :created_at, :datetime, null: true
    change_column :answer_links,
      :updated_at, :datetime, null: true
  end
end
