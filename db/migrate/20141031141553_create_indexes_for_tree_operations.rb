class CreateIndexesForTreeOperations < ActiveRecord::Migration
  def self.up
    add_index :questionnaire_parts, :parent_id
    add_index :loop_item_types, :parent_id
    add_index :loop_items, :parent_id
  end

  def self.down
  end
end
