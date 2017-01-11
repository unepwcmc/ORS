class DowncaseAllExistingEmails < ActiveRecord::Migration
  def up
    add_index :users, :email, unique: true
    # Downcases all existing emails to ensure this isn't an issue when a user is resetting their password
    # If by downcasing duplicates would be introduced, this will fail
    execute 'UPDATE users SET email = LOWER(email)'
  end

  def down
  end
end
