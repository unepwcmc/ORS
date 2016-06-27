class AddOriginalIdToDelegations < ActiveRecord::Migration
  def self.up
    add_column :delegations, :original_id, :integer
    add_foreign_key(:delegations, :delegations, {:column => :original_id, :dependent => :nullify})
    add_column :delegation_sections, :original_id, :integer
    add_foreign_key(:delegation_sections, :delegation_sections, {:column => :original_id, :dependent => :nullify})
  end

  def self.down
  end
end
