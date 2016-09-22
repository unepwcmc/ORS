class AddConstraintsToMultiAnswers < ActiveRecord::Migration
  def up
    # make single NOT NULL
    execute <<-SQL
      UPDATE multi_answers SET single = FALSE
      WHERE single IS NULL
    SQL

    change_column :multi_answers,
      :single, :boolean, null: false, default: false

    # make other_required NOT NULL
    execute <<-SQL
      UPDATE multi_answers SET other_required = FALSE
      WHERE other_required IS NULL
    SQL

    change_column :multi_answers,
      :other_required, :boolean, null: false, default: false

    # make display_type NOT NULL
    execute <<-SQL
      UPDATE multi_answers SET display_type = 0
      WHERE display_type IS NULL
    SQL

    change_column :multi_answers,
      :display_type, :integer, null: false

    # make timestamps NOT NULL
    execute "UPDATE multi_answers SET created_at = NOW() WHERE created_at IS NULL"
    change_column :multi_answers, :created_at, :datetime, null: false
    execute "UPDATE multi_answers SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :multi_answers, :updated_at, :datetime, null: false
  end

  def down
    change_column :multi_answers,
      :single, :boolean, null: true
    change_column :multi_answers,
      :other_required, :boolean, null: true
    change_column :multi_answers,
      :display_type, :integer, null: true

    change_column :multi_answers,
      :created_at, :datetime, null: true
    change_column :multi_answers,
      :updated_at, :datetime, null: true
  end
end
