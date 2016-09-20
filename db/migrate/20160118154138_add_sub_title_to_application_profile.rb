class AddSubTitleToApplicationProfile < ActiveRecord::Migration
  def change
    add_column :application_profiles, :sub_title, :string, default: ''
  end
end
