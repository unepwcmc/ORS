class AddTitleTranslationsInApplicationProfile < ActiveRecord::Migration
  def up
    rename_column :application_profiles, :title, :title_en
    add_column :application_profiles, :title_fr, :string, default: ''
    add_column :application_profiles, :title_es, :string, default: ''
  end

  def down
    rename_column :application_profiles, :title_en, :title
    remove_column :application_profiles, :title_fr
    remove_column :application_profiles, :title_es
  end
end
