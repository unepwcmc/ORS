class AddIndexOnRgt < ActiveRecord::Migration
  def self.up
    unless index_exists?(:questionnaire_parts, :rgt)
      add_index :questionnaire_parts, :rgt
    end
    unless index_exists?(:loop_item_types, :rgt)
      add_index :loop_item_types, :rgt
    end
    unless index_exists?(:loop_items, :rgt)
      add_index :loop_items, :rgt
    end
  end

  def self.down
  end
end
