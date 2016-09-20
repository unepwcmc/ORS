set :rails_env, "production"

# Primary domain name of your application. Used in the Apache configs
set :domain, "unepwcmc-014.vm.brightbox.net"

## List of servers
server "unepwcmc-014.vm.brightbox.net", :app, :web, :db, :primary => true
