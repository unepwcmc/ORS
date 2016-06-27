class AddOriginalIdToQuestionnaireParts < ActiveRecord::Migration
  def self.up
    add_column :questions, :original_id, :integer
    add_foreign_key(:questions, :questions, {:column => :original_id, :dependent => :nullify})
    add_column :sections, :original_id, :integer
    add_foreign_key(:sections, :sections, {:column => :original_id, :dependent => :nullify})
    add_column :questionnaire_parts, :original_id, :integer
    add_foreign_key(:questionnaire_parts, :questionnaire_parts, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
    remove_column :questions, :original_id
    remove_column :sections, :original_id
    remove_column :questionnaire_parts, :original_id
  end
end
