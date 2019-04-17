# config valid only for current version of Capistrano
lock '3.11.0'

set :application, proc { fetch(:stage).split(':').reverse[1] }

set :repo_url, 'git@github.com:unepwcmc/ORS.git'

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.2.3'

set :deploy_user, 'wcmc'

set :deploy_to, "/home/#{fetch(:deploy_user)}/#{fetch(:application)}"

set :backup_path, "/home/#{fetch(:deploy_user)}/Backup"

#set :scm, :git
set :scm_username, "unepwcmc-read"

set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'private')

set :linked_files, %w{config/database.yml .env}

set :ssh_options, { forward_agent: true,}

set :pty, true

set :keep_releases, 5

set :passenger_restart_with_touch, false


# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5


require 'appsignal/capistrano'
