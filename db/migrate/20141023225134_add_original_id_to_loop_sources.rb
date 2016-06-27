class AddOriginalIdToLoopSources < ActiveRecord::Migration
  def self.up
    add_column :loop_sources, :original_id, :integer
    add_foreign_key(:loop_sources, :loop_sources, {:column => :original_id, :dependent => :nullify})
    add_column :filtering_fields, :original_id, :integer
    add_foreign_key(:filtering_fields, :filtering_fields, {:column => :original_id, :dependent => :nullify})
    add_column :loop_item_types, :original_id, :integer
    add_foreign_key(:loop_item_types, :loop_item_types, {:column => :original_id, :dependent => :nullify})
    add_column :loop_item_names, :original_id, :integer
    add_foreign_key(:loop_item_names, :loop_item_names, {:column => :original_id, :dependent => :nullify})
    add_column :loop_items, :original_id, :integer
    add_foreign_key(:loop_items, :loop_items, {:column => :original_id, :dependent => :nullify})
    add_column :extras, :original_id, :integer
    add_foreign_key(:extras, :extras, {:column => :original_id, :dependent => :nullify})
    add_column :item_extras, :original_id, :integer
    add_foreign_key(:item_extras, :item_extras, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
  end
end
