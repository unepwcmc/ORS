class AddEnableSuperDelegatesToQuestionnaire < ActiveRecord::Migration
  def change
    add_column :questionnaires, :enable_super_delegates, :boolean, default: true
  end
end
