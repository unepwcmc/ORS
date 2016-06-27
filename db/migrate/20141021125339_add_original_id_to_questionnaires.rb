class AddOriginalIdToQuestionnaires < ActiveRecord::Migration
  def self.up
    add_column :questionnaires, :original_id, :integer
    add_foreign_key(:questionnaires, :questionnaires, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
    remove_column :questionnaires, :original_id
  end
end
