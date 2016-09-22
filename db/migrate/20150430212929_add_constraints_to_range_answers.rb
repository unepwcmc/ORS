class AddConstraintsToRangeAnswers < ActiveRecord::Migration
  def up
    # make timestamps NOT NULL
    execute "UPDATE range_answers SET created_at = NOW() WHERE created_at IS NULL"
    change_column :range_answers, :created_at, :datetime, null: false
    execute "UPDATE range_answers SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :range_answers, :updated_at, :datetime, null: false
  end

  def down
    change_column :range_answers,
      :created_at, :datetime, null: true
    change_column :range_answers,
      :updated_at, :datetime, null: true
  end
end
