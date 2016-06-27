class AddAllowAttachmentsToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :allow_attachments, :boolean, :default => true
  end

  def self.down
    remove_column :questions, :allow_attachments
  end
end
