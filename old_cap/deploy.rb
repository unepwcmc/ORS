## Generated with 'brightbox-capify' on 2015-02-10 08:02:36 +0000
gem 'brightbox', '>=2.4.4'
require 'brightbox/recipes'
require 'brightbox/passenger'

set :default_stage, 'staging'
require 'capistrano/ext/multistage'
require 'rvm/capistrano'
set :rvm_ruby_string, 'ruby-2.0.0-p353@ort3'
set :rvm_type, :user
require 'capistrano/sidekiq'
set :sidekiq_options, '--config config/sidekiq.yml'

# The name of your application.  Used for deployment directory and filenames
# and Apache configs. Should be unique on the Brightbox
set :application, "ort-bern20"

# Primary domain name of your application. Used in the Apache configs
set :domain, "unepwcmc-011.vm.brightbox.net"

## List of servers
server "unepwcmc-011.vm.brightbox.net", :app, :web, :db, :primary => true

# Target directory for the application on the web and app servers.
set(:deploy_to) { File.join("", "home", user, application) }

# URL of your source repository. By default this will just upload
# the local directory.  You should probably change this if you use
# another repository, like git or subversion.

set :repository, "git@github.com:unepwcmc/online_reporting_tool.git"
set :branch, "bern-ruby20"
set :deploy_via, :remote_cache
set :copy_exclude, [ '.git' ]

### Other options you can set ###
# Comma separated list of additional domains for Apache
# set :domain_aliases, "www.example.com,dev.example.com"

## Dependencies
# Set the commands and gems that your application requires. e.g.
# depend :remote, :gem, "will_paginate", ">=2.2.2"
# depend :remote, :command, "brightbox"
#
# If you're using Bundler, then you don't need to specify your
# gems here as well as there (and the bundler gem is installed for
# you automatically). If you're not using bundler, uncomment the
# following line to explicitly disable it
# set :bundle_disable, true
#
# Gem with a source (such as github)
# depend :remote, :gem, "tmm1-amqp", ">=0.6.0", :source => "http://gems.github.com"
#
# Specify your specific Rails version if it is not vendored
# depend :remote, :gem, "rails", "=2.2.2"
#
# Set the apt packages your application or gems require. e.g.
# depend :remote, :apt, "libxml2-dev"

## Local Shared Area
# These are the list of files and directories that you want
# to share between the releases of your application on a particular
# server. It uses the same shared area as the log files.
#
# NOTE: local areas trump global areas, allowing you to have some
# servers using local assets if required.
#
# So if you have an 'upload' directory in public, add 'public/upload'
# to the :local_shared_dirs array.
# If you want to share the database.yml add 'config/database.yml'
# to the :local_shared_files array.
#
# The shared area is prepared with 'deploy:setup' and all the shared
# items are symlinked in when the code is updated.
set :local_shared_dirs, %w(private public/system)
set :local_shared_files, %w(.env config/database.yml)

## Global Shared Area
# These are the list of files and directories that you want
# to share between all releases of your application across all servers.
# For it to work you need a directory on a network file server shared
# between all your servers. Specify the path to the root of that area
# in :global_shared_path. Defaults to the same value as :shared_path.
# set :global_shared_path, "/srv/share/myapp"
#
# NOTE: local areas trump global areas, allowing you to have some
# servers using local assets if required.
#
# Beyond that it is the same as the local shared area.
# So if you have an 'upload' directory in public, add 'public/upload'
# to the :global_shared_dirs array.
# If you want to share the database.yml add 'config/database.yml'
# to the :global_shared_files array.
#
# The shared area is prepared with 'deploy:setup' and all the shared
# items are symlinked in when the code is updated.
# set :global_shared_dirs, %w(public/upload)
# set :global_shared_files, %w(config/database.yml)

# SSL Certificates. If you specify an SSL certificate name then
# the gem will create an 'https' configuration for this application
# TODO: Upload and install the keys on the server
# set :ssl_certificate, "/path/to/certificate/for/my_app.crt"
# set :ssl_key, "/path/to/key/for/my_app.key
# or
# set :ssl_certificate, "name_of_installed_certificate"

## Static asset caching.
# By default static assets served directly by the web server are
# cached by the client web browser for 10 years, and cache invalidation
# of static assets is handled by the Rails helpers using asset
# timestamping.
# You may need to adjust this value if you have hard coded static
# assets, or other special cache requirements. The value is in seconds.
# set :max_age, 315360000

# SSH options. The forward agent option is used so that loopback logins
# with keys work properly
ssh_options[:forward_agent] = true

# Forces a Pty so that svn+ssh repository access will work. You
# don't need this if you are using a different SCM system. Note that
# ptys stop shell startup scripts from running.
default_run_options[:pty] = true

## Logrotation
# Where the logs are stored. Defaults to <shared_path>/log
# set :log_dir, "central/log/path"
# The size at which to rotate a log. e.g 1G, 100M, 5M. Defaults to 100M
# set :log_max_size, "100M"
# How many old compressed logs to keep. Defaults to 10
# set :log_keep, "10"

## Version Control System
# Which version control system. Defaults to subversion if there is
# no 'set :scm' command.
set :scm, :git
set :scm_username, "unepwcmc-read"
set :git_enable_submodules, 1

## Deployment settings
# The brightbox gem deploys as the user 'rails' by default and
# into the 'production' environment. You can change these as required.
# set :user, "rails"
set :use_sudo, false
set :rails_env, :staging

## Command running settings
# use_sudo is switched off by default so that commands are run
# directly as 'user' by the run command. If you switch on sudo
# make sure you set the :runner variable - which is the user the
# capistrano default tasks use to execute commands.
# NOTE: This just affects the default recipes unless you use the
# 'try_sudo' command to run your commands. The 'try_sudo' command
# has been deprecated in favour of 'run "#{sudo} <command>"' syntax.
# set :use_sudo, false
# set :runner, user## Passenger Configuration
# Set the method of restarting passenger
# :soft is the default and just touches tmp/restart.txt as normal.
# :hard forcibly kills running instances, rarely needed now but used
# to be necessary with older versions of passenger
# set :passenger_restart_strategy, :soft

desc "Configure Database"
task :setup_database_configuration do
  db_host = Capistrano::CLI.ui.ask("Database IP address: ")
  db_port = Capistrano::CLI.ui.ask("Database port: ")
  db_name = Capistrano::CLI.ui.ask("Database name: ")
  db_user = Capistrano::CLI.ui.ask("Database username: ")
  db_password = Capistrano::CLI.password_prompt("Database user password: ")
  require 'yaml'
  spec = {
    rails_env => {
      'adapter' => "postgresql",
      'database' => db_name.to_s,
      'port' => db_port.to_s,
      'username' => db_user.to_s,
      'host' => db_host.to_s,
      'password' => db_password.to_s
    }
  }
  run "mkdir -p #{shared_path}/config"
  put(spec.to_yaml, "#{shared_path}/config/database.yml")
end
after "deploy:setup", :setup_database_configuration

desc "Configure .env"
task :setup_dotenv_configuration do
  secret_key_base = Capistrano::CLI.ui.ask("Secret key base (for secret token): ")
  exception_notification_email = Capistrano::CLI.ui.ask("Email address(for exception notifications): ")
  exception_notification_slack_webhook = Capistrano::CLI.ui.ask("Slack webhook (for exception notifications): ")
  mailer_address = Capistrano::CLI.ui.ask("Mailer address: ")
  mailer_port = Capistrano::CLI.ui.ask("Mailer port: ")
  mailer_domain = Capistrano::CLI.ui.ask("Mailer domain: ")
  mailer_username = Capistrano::CLI.ui.ask("Mailer username: ")
  mailer_password = Capistrano::CLI.ui.ask("Mailer password: ")
  mailer_asset_host = Capistrano::CLI.ui.ask("Mailer asset host: ")
  mailer_host = Capistrano::CLI.ui.ask("Mailer host: ")
  redis_url = Capistrano::CLI.ui.ask("Redis server URL: ")
  dotenv = <<-EOF
SECRET_KEY_BASE=#{secret_key_base}
EXCEPTION_NOTIFICATION_EMAIL=#{exception_notification_email}
EXCEPTION_NOTIFICATION_SLACK_WEBHOOK=#{exception_notification_slack_webhook}
MAILER_ADDRESS_KEY=#{mailer_address}
MAILER_PORT_KEY=#{mailer_port}
MAILER_DOMAIN_KEY=#{mailer_domain}
MAILER_USERNAME_KEY=#{mailer_username}
MAILER_PASSWORD_KEY=#{mailer_password}
MAILER_ASSET_HOST_KEY=#{mailer_asset_host}
MAILER_HOST_KEY=#{mailer_host}
REDIS_NAMESPACE=ORS
REDIS_URL=#{redis_url}

  EOF
  run "mkdir -p #{shared_path}/config"
  put(dotenv, "#{shared_path}/.env")
end
after "deploy:setup", :setup_dotenv_configuration

set :generate_webserver_config, false
desc "Configure VHost"
task :setup_vhost_configuration do
  vhost_config =<<-EOF
    server {
      listen 80;
      client_max_body_size 4G;
      server_name #{application}.#{domain};
      keepalive_timeout 5;
      root #{deploy_to}/current/public;
      passenger_enabled on;
      passenger_ruby /home/rails/.rvm/wrappers/ruby-2.0.0-p353@ort3/ruby;
      rails_env #{rails_env};
    }
  EOF
  put vhost_config, "/tmp/vhost_config"
  sudo "mv /tmp/vhost_config /etc/nginx/sites-available/#{application}"
  sudo "ln -s /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"
end
after "deploy:setup", :setup_vhost_configuration
