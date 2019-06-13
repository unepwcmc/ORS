class AddApiAccesFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :has_api_access, :boolean, default: true
  end
end
