class AddSignUpBoxBoolToApplicationProfile < ActiveRecord::Migration
  def change
    add_column :application_profiles, :show_sign_up, :boolean, default: true
  end
end
