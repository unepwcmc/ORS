class AddConstraintsToCsvFiles < ActiveRecord::Migration
  def up
    # make timestamps NOT NULL
    execute "UPDATE csv_files SET created_at = NOW() WHERE created_at IS NULL"
    change_column :csv_files, :created_at, :datetime, null: false
    execute "UPDATE csv_files SET updated_at = NOW() WHERE updated_at IS NULL"
    change_column :csv_files, :updated_at, :datetime, null: false
  end

  def down
    change_column :csv_files,
      :created_at, :datetime, null: true
    change_column :csv_files,
      :updated_at, :datetime, null: true
  end
end
