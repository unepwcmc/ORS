class CreateApplicationProfiles < ActiveRecord::Migration
  def change
    create_table :application_profiles do |t|
      t.string :title, default: ""
      t.string :short_title, default: ""
      t.text :logo_url, default: ""
      t.timestamps
    end
  end
end
