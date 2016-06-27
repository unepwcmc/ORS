class RemoveDeletedFieldFromTables < ActiveRecord::Migration
  def self.up
    remove_column :answers, :deleted
    remove_column :answer_parts, :deleted
    remove_column :loop_items, :deleted
    remove_column :loop_sources, :deleted
    remove_column :multi_answers, :deleted
    remove_column :multi_answer_options, :deleted
    remove_column :questions, :deleted
    remove_column :sections, :deleted
    remove_column :text_answers, :deleted
    remove_column :text_answer_fields, :deleted
  end

  def self.down
    add_column :answers, :deleted, :boolean, :default => false
    add_column :answer_parts, :deleted, :boolean, :default => false
    add_column :loop_items, :deleted, :boolean, :default => false
    add_column :loop_sources, :deleted, :boolean, :default => false
    add_column :multi_answers, :deleted, :boolean, :default => false
    add_column :multi_answer_options, :deleted, :boolean, :default => false
    add_column :questions, :deleted, :boolean, :default => false
    add_column :sections, :deleted, :boolean, :default => false
    add_column :text_answers, :deleted, :boolean, :default => false
    add_column :text_answer_fields, :deleted, :boolean, :default => false
  end
end
