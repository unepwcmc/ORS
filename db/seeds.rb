# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
admin = Role.where(name: 'admin').first_or_create
respondent = Role.where(name: 'respondent').first_or_create
Role.where(name: 'delegate').first_or_create
Role.where(name: 'super_delegate').first_or_create
puts "#{Role.count} role created. admin, respondent, delegate and super_delegate"
user = User.create(:first_name => "My", :last_name => "Admin",
            :email => "admin@unep-wcmc.org", :password => "admin",
            :password_confirmation => "admin")
puts "#{User.count} user created. email: #{user.email} ; password: admin"
user.roles << admin
user.roles << respondent
