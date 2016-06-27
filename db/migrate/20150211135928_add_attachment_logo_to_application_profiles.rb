class AddAttachmentLogoToApplicationProfiles < ActiveRecord::Migration
  def self.up
    change_table :application_profiles do |t|
      t.attachment :logo
    end
  end

  def self.down
    drop_attached_file :application_profiles, :logo
  end
end
