class AddOrderIndexToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :order_index, :integer, null: true
  end
end
