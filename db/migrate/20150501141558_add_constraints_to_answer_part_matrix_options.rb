class AddConstraintsToAnswerPartMatrixOptions < ActiveRecord::Migration
  def up
    # add foreign key constraint
    add_index :answer_part_matrix_options, :matrix_answer_drop_option_id,
      name: 'index_answer_part_matrix_options_on_drop_option_id'
    execute <<-SQL
      DELETE FROM answer_part_matrix_options
      WHERE matrix_answer_drop_option_id IS NOT NULL
      AND matrix_answer_drop_option_id NOT IN (
        SELECT id FROM matrix_answer_drop_options
      )
    SQL

    add_foreign_key :answer_part_matrix_options,
      :matrix_answer_drop_options, {
        column: :matrix_answer_drop_option_id,
        dependent: :delete,
        name: 'answer_part_matrix_options_drop_option_id_fk'
      }

    # add foreign key constraint
    add_index :answer_part_matrix_options, :matrix_answer_option_id
    execute <<-SQL
      DELETE FROM answer_part_matrix_options
      WHERE matrix_answer_option_id IS NOT NULL
      AND matrix_answer_option_id NOT IN (
        SELECT id FROM matrix_answer_options
      )
    SQL

    add_foreign_key :answer_part_matrix_options,
      :matrix_answer_options, {
        column: :matrix_answer_option_id,
        dependent: :delete,
        name: 'answer_part_matrix_options_option_id_fk'
      }

    # make answer_part_id NOT NULL & add foreign key constraint
    add_index :answer_part_matrix_options, :answer_part_id
    execute <<-SQL
      WITH answer_part_ids AS (SELECT id FROM answer_parts),
      answer_part_matrix_options_to_delete AS (
        SELECT * FROM answer_part_matrix_options
        EXCEPT
        SELECT answer_part_matrix_options.*
        FROM answer_part_matrix_options
        JOIN answer_part_ids
        ON answer_part_ids.id = answer_part_matrix_options.answer_part_id
      )
      DELETE FROM answer_part_matrix_options t
      USING answer_part_matrix_options_to_delete td
      WHERE t.id = td.id
    SQL

    change_column :answer_part_matrix_options,
      :answer_part_id, :integer, null: false
    add_foreign_key :answer_part_matrix_options,
      :answer_parts, {
        column: :answer_part_id,
        dependent: :delete,
        name: 'answer_part_matrix_options_answer_part_id_fk'
      }

    # make timestamps NOT NULL
    execute "UPDATE answer_part_matrix_options SET created_at = NOW() WHERE created_at IS NULL"
    change_column :answer_part_matrix_options, :created_at, :datetime, null: false
    execute "UPDATE answer_part_matrix_options SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :answer_part_matrix_options, :updated_at, :datetime, null: false
  end

  def down
    remove_index :answer_part_matrix_options,
      name: 'index_answer_part_matrix_options_on_drop_option_id'
    remove_foreign_key :answer_part_matrix_options,
      name: 'answer_part_matrix_options_drop_option_id_fk'

    remove_index :answer_part_matrix_options, :matrix_answer_option_id
    remove_foreign_key :answer_part_matrix_options,
      name: 'answer_part_matrix_options_option_id_fk'

    remove_index :answer_part_matrix_options, :answer_part_id
    change_column :answer_part_matrix_options,
      :answer_part_id, :integer, null: true
    remove_foreign_key :answer_part_matrix_options,
      name: 'answer_part_matrix_options_answer_part_id_fk'

    change_column :answer_part_matrix_options,
      :created_at, :datetime, null: true
    change_column :answer_part_matrix_options,
      :updated_at, :datetime, null: true
  end
end
