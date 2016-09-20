class AddConstraintsToMatrixAnswers < ActiveRecord::Migration
  def up
    # make display_reply NOT NULL
    execute <<-SQL
      UPDATE matrix_answers SET display_reply = 0
      WHERE display_reply IS NULL
    SQL

    change_column :matrix_answers,
      :display_reply, :integer, null: false

    # make matrix_orientation NOT NULL
    execute <<-SQL
      UPDATE matrix_answers SET matrix_orientation = 0
      WHERE matrix_orientation IS NULL
    SQL

    change_column :matrix_answers,
      :matrix_orientation, :integer, null: false

    # make timestamps NOT NULL
    execute "UPDATE matrix_answers SET created_at = NOW() WHERE created_at IS NULL"
    change_column :matrix_answers, :created_at, :datetime, null: false
    execute "UPDATE matrix_answers SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :matrix_answers, :updated_at, :datetime, null: false
  end

  def down
    change_column :matrix_answers,
      :display_reply, :integer, null: true
    change_column :matrix_answers,
      :matrix_orientation, :integer, null: true

    change_column :matrix_answers,
      :created_at, :datetime, null: true
    change_column :matrix_answers,
      :updated_at, :datetime, null: true
  end
end
