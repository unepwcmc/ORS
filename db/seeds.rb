# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

# Create roles if they don't exist

admin               = Role.where(name: "admin").first_or_create do |r|
                        r.order_index = 1
                        puts "Created admin role"
                      end

respondent          = Role.where(name: "respondent").first_or_create do |r|
                        r.order_index = 3
                        puts "Created respondent role"
                      end

delegate_role       = Role.where(name: "delegate").first_or_create do |r|
                        r.order_index = 5
                        puts "Created delegate role"
                      end

super_delegate_role = Role.where(name: 'super_delegate').first_or_create do |r|
                        r.order_index = 4
                        puts "Created super delegate role"
                      end

respondent_admin_role = Role.where(name: 'respondent_admin').first_or_create do |r|
                          r.order_index = 2
                          puts "Created respondent admin role"
                        end

puts "Roles order index updated"

# Create admin user if it does not exist

user_created = false

user =  User.where(email: "admin@unep-wcmc.org").first_or_create do |u|
          u.first_name            = "My"
          u.last_name             = "Admin"
          u.password              = Rails.application.secrets[:admin_pwd]
          u.password_confirmation = Rails.application.secrets[:admin_pwd]

          user_created = true

          puts "Admin user created with... \n\t Email: #{u.email}"
        end

# Assign roles to admin user if it was just created

if user_created
  user.roles << admin
  user.roles << respondent
end
