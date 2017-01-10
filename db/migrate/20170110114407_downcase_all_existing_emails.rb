class DowncaseAllExistingEmails < ActiveRecord::Migration
  def up
    # Downcases all existing emails to ensure this isn't an issue when a user is resetting their password
    User.all.each do |u|
      u.email.downcase!
      u.save
    end
  end

  def down
  end
end
