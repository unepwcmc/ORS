class RemoveDeletedFromQuestionnaires < ActiveRecord::Migration
  def self.up
    remove_column :questionnaires, :deleted
  end

  def self.down
    add_column :questionnaires, :deleted, :boolean, :default => false
  end
end
