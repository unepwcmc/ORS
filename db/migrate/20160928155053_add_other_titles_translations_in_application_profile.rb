class AddOtherTitlesTranslationsInApplicationProfile < ActiveRecord::Migration
  def up
    rename_column :application_profiles, :short_title, :short_title_en
    add_column :application_profiles, :short_title_fr, :string, default: ''
    add_column :application_profiles, :short_title_es, :string, default: ''
    rename_column :application_profiles, :sub_title, :sub_title_en
    add_column :application_profiles, :sub_title_fr, :string, default: ''
    add_column :application_profiles, :sub_title_es, :string, default: ''
  end

  def down
    rename_column :application_profiles, :short_title_en, :short_title
    remove_column :application_profiles, :short_title_fr
    remove_column :application_profiles, :short_title_es
    rename_column :application_profiles, :sub_title_en, :sub_title
    remove_column :application_profiles, :sub_title_fr
    remove_column :application_profiles, :sub_title_es
  end
end
