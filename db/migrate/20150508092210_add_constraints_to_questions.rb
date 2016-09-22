class AddConstraintsToQuestions < ActiveRecord::Migration
  def up
    # these columns are empty in all instances of ORS & not referenced in the code
    remove_column :questions, :type
    remove_column :questions, :ordering
    remove_column :questions, :number

    # make section_id NOT NULL & add foreign key constraint
    add_index :questions, :section_id
    execute <<-SQL
      WITH questions_to_delete AS (
        SELECT * FROM questions
        EXCEPT
        SELECT questions.* FROM questions
        JOIN sections ON sections.id = questions.section_id
      )
      DELETE FROM questions t
      USING questions_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :questions,
      :section_id, :integer, null: false
    add_foreign_key :questions,
      :sections, {
        column: :section_id,
        dependent: :delete
      }

    # make timestamps NOT NULL
    execute "UPDATE questions SET created_at = NOW() WHERE created_at IS NULL"
    change_column :questions, :created_at, :datetime, null: false
    execute "UPDATE questions SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :questions, :updated_at, :datetime, null: false
  end

  def down
    add_column :questions, :type, :integer
    add_column :questions, :ordering, :integer
    add_column :questions, :number, :integer

    remove_index :questions, :section_id
    change_column :questions,
      :section_id, :integer, null: true
    remove_foreign_key :questions, column: :section_id

    change_column :questions,
      :created_at, :datetime, null: true
    change_column :questions,
      :updated_at, :datetime, null: true
  end

end
