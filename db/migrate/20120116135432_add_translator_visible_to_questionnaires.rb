class AddTranslatorVisibleToQuestionnaires < ActiveRecord::Migration
  def self.up
    unless column_exists?(:questionnaires, :translator_visible)
      add_column :questionnaires, :translator_visible, :boolean, default: false
    end
  end

  def self.down
    if column_exists?(:questionnaires, :translator_visible)
      remove_column :questionnaires, :translator_visible
    end
  end
end
