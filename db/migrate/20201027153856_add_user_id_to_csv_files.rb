class AddUserIdToCsvFiles < ActiveRecord::Migration
  def change
    add_column :csv_files, :user_id, :integer, references: :user, index: true, null: true, foreign_key: true
  end
end
