class AddDefaultToPerishableToken < ActiveRecord::Migration
  def change
    change_column :users, :perishable_token, :string, default: ''
  end
end
