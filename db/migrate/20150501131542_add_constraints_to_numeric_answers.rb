class AddConstraintsToNumericAnswers < ActiveRecord::Migration
  def up
    # make timestamps NOT NULL
    execute "UPDATE numeric_answers SET created_at = NOW() WHERE created_at IS NULL"
    change_column :numeric_answers, :created_at, :datetime, null: false
    execute "UPDATE numeric_answers SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :numeric_answers, :updated_at, :datetime, null: false
  end

  def down
    change_column :numeric_answers,
      :created_at, :datetime, null: true
    change_column :numeric_answers,
      :updated_at, :datetime, null: true
  end
end
