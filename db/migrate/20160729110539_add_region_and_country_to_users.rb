class AddRegionAndCountryToUsers < ActiveRecord::Migration
  def change
    add_column :users, :region, :text, default: ''
    add_column :users, :country, :text, default: ''
  end
end
