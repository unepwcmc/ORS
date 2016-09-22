class AddConstraintsToTaggings < ActiveRecord::Migration
  def up
    # make tag_id NOT NULL & add foreign key constraint
    # index on tag_id already in place
    execute <<-SQL
      WITH taggings_to_delete AS (
        SELECT * FROM taggings
        EXCEPT
        SELECT taggings.*
        FROM taggings
        JOIN tags
        ON taggings.tag_id = tags.id
      )
      DELETE FROM taggings t
      USING taggings_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :taggings,
      :tag_id, :integer, null: false
    add_foreign_key :taggings,
      :tags, {
        column: :tag_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE taggings SET created_at = NOW() WHERE created_at IS NULL"
    change_column :taggings, :created_at, :datetime, null: false
  end

  def down
    change_column :taggings,
      :tag_id, :integer, null: true
    remove_foreign_key :taggings, column: :tag_id

    change_column :taggings,
      :created_at, :datetime, null: true
  end
end
