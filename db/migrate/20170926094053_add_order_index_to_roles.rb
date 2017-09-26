class AddOrderIndexToRoles < ActiveRecord::Migration
  def up
    add_column :roles, :order_index, :integer, null: true

    Role.find_by_name('admin').try { |r| r.update_attributes(order_index: 1) }
    Role.find_by_name('respondent_admin').try { |r| r.update_attributes(order_index: 2) }
    Role.find_by_name('respondent').try { |r| r.update_attributes(order_index: 3) }
    Role.find_by_name('super_delegate').try { |r| r.update_attributes(order_index: 4) }
    Role.find_by_name('delegate').try { |r| r.update_attributes(order_index: 5) }
  end

  def down
    remove_column :roles, :order_index
  end
end
