class AddOriginalIdToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :original_id, :integer
    add_foreign_key(:documents, :documents, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
  end
end
