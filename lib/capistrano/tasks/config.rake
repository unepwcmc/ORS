namespace :config do
  task :setup do
    ask(:db_user, 'db_user')
    ask(:db_pass, 'db_pass')
    ask(:db_name, 'db_name')
    ask(:db_host, 'db_host')
    setup_config = <<-EOF
#{fetch(:rails_env)}:
  adapter: postgresql
  database: #{fetch(:db_name)}
  username: #{fetch(:db_user)}
  password: #{fetch(:db_pass)}
  host: #{fetch(:db_host)}
EOF
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      upload! StringIO.new(setup_config), "#{shared_path}/config/database.yml"
    end
  end
end

namespace :config do
  task :setup do
    ask(:secret_key_base, 'secret_key_base')
    ask(:exception_notification_email, 'exception_notification_email')
    ask(:exception_notification_slack_webhook, 'exception_notification_slack_webhook')
    ask(:mailer_address, 'mailer_address')
    ask(:mailer_port, 'mailer_port')
    ask(:mailer_domain, 'mailer_domain')
    ask(:mailer_username, 'mailer_username')
    ask(:mailer_password, 'mailer_password')
    ask(:mailer_asset_host, 'mailer_asset_host')
    ask(:mailer_host, 'mailer_host')
    ask(:redis_url, 'redis_url')
    ask(:instiki_url, 'instiki_url')
env_config = <<-EOF
SECRET_KEY_BASE=#{fetch(:secret_key_base)}
EXCEPTION_NOTIFICATION_EMAIL=#{fetch(:exception_notification_email)}
EXCEPTION_NOTIFICATION_SLACK_WEBHOOK=#{fetch(:exception_notification_slack_webhook)}
MAILER_ADDRESS_KEY=#{fetch(:mailer_address)}
MAILER_PORT_KEY=#{fetch(:mailer_port)}
MAILER_DOMAIN_KEY=#{fetch(:mailer_domain)}
MAILER_USERNAME_KEY=#{fetch(:mailer_username)}
MAILER_PASSWORD_KEY=#{fetch(:mailer_password)}
MAILER_ASSET_HOST_KEY=#{fetch(:mailer_asset_host)}
MAILER_HOST_KEY=#{fetch(:mailer_host)}
REDIS_NAMESPACE=ORS
REDIS_URL=#{fetch(:redis_url)}
INSTIKI_URL=#{fetch(:instiki_url)}
EOF
    on roles(:app) do
      execute "mkdir -p #{shared_path}"
      upload! StringIO.new(env_config), "#{shared_path}/.env"
    end
  end
end

namespace :config do
  task :setup do
  vhost_config =<<-EOF
server {
  listen 80;
  client_max_body_size 200M;
  server_name #{fetch(:server_name)};
  keepalive_timeout 5;
  root #{deploy_to}/current/public;
  passenger_enabled on;
  passenger_ruby /home/#{fetch(:deploy_user)}/.rvm/gems/#{fetch(:rvm_ruby_version)}/wrappers/ruby;
  rails_env #{fetch(:rails_env)};
  gzip on;
  location ^~ /assets/ {
    expires max;
    add_header Cache-Control public;
  }
  error_page 503 @503;
  # Return a 503 error if the maintenance page exists.
  if (-f #{deploy_to}shared/public/system/maintenance.html) {
    return 503;
  }
  location @503 {
    # Serve static assets if found.
    if (-f $request_filename) {
      break;
    }
    # Set root to the shared directory.
    root #{deploy_to}/shared/public;
    rewrite ^(.*)$ /system/maintenance.html break;
  }
}
EOF

  on roles(:app) do
     execute "sudo mkdir -p /etc/nginx/sites-available"
     upload! StringIO.new(vhost_config), "/tmp/vhost_config"
     execute "sudo mv /tmp/vhost_config /etc/nginx/sites-available/#{fetch(:application)}"
     execute "sudo ln -s /etc/nginx/sites-available/#{fetch(:application)} /etc/nginx/sites-enabled/#{fetch(:application)}"
    end
  end
end

namespace :config do
  task :setup do
    ask(:s3_access_key_id, 's3_access_key_id')
    ask(:s3_secret_access_key, 's3_secret_access_key')
    ask(:s3_bucket, 's3_bucket')
    ask(:mail_server, 'mail_server')
    backup_config_db = <<-EOF
#  encoding: utf-8
##
# Backup Generated: #{fetch(:application)}_website
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t #{fetch(:application)}_website [-c <path_to_configuration_file>]
#
Model.new(:#{fetch(:application)}_website_db, '#{fetch(:application)}_website_db') do
  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 250 megabytes
  # if the backup file size exceeds 250 megabytes
  #
  # split_into_chunks_of 250
  ##
  # PostgreSQL [Database]
  #
  database PostgreSQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = "#{fetch(:db_name)}"
    db.username           = "#{fetch(:db_user)}"
    db.password           = "#{fetch(:db_pass)}"
    db.host               = "#{fetch(:db_host)}"
    db.port               = 5432
    db.socket             = "/tmp/pg.sock"
    # When dumping all databases, `skip_tables` and `only_tables` are ignored.
    db.skip_tables        = ["skip", "these", "tables"]
    db.only_tables        = ["only", "these", "tables"]
    db.additional_options = ["-xc", "-E=utf8"]
  end
  ##
  # Amazon Simple Storage Service [Storage]
  #
  # See the documentation on the Wiki for details.
  # https://github.com/meskyanichi/backup/wiki/Storages
  store_with S3 do |s3|
   # AWS Credentials
    s3.access_key_id     = "#{fetch(:s3_access_key_id)}"
    s3.secret_access_key = "#{fetch(:s3_secret_access_key)}"
    # Or, to use a IAM Profile:
    # s3.use_iam_profile = true
    s3.region            = "us-east-1"
    s3.bucket            = "#{fetch(:s3_bucket)}"
    s3.path              = "/db"
  end
  ##
  # Bzip2 [Compressor]
  #
  compress_with Bzip2
##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the Wiki for other delivery options.
  # https://github.com/meskyanichi/backup/wiki/Notifiers
  #
  notify_by Mail do |mail|
    mail.on_success           = true
    mail.on_warning           = true
    mail.on_failure           = true
    mail.from                 = "#{fetch(:mailer_username)}"
   mail.to                   = "stuart.watson@unep-wcmc.org"
    mail.address              = "#{fetch(:mailer_address)}"
    mail.port                 = 587
    mail.domain               = "your.host.name"
    mail.user_name            = "#{fetch(:mailer_username)}"
    mail.password             = "#{fetch(:mailer_password)}"
    mail.authentication       = "login"
    mail.encryption           = :starttls
  end
 end
end
EOF

    on roles(:db) do
      execute "mkdir -p #{fetch(:backup_path)}/models"
      upload! StringIO.new(backup_config_db), "#{fetch(:backup_path)}/models/db_#{fetch(:application)}.rb"
    end
  end
end

namespace :config do
  task :setup do
    backup_config_files = <<-EOF
# encoding: utf-8
# Backup Generated: #{fetch(:application)}_files
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t #{fetch(:application)}_files [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://meskyanichi.github.io/backup
#
Model.new(:#{fetch(:application)}_files, '#{fetch(:application)}_files') do
  ##
  # Amazon Simple Storage Service [Storage]
  #
  store_with S3 do |s3|
    # AWS Credentials
    s3.access_key_id     = "#{fetch(:s3_access_key_id)}"
    s3.secret_access_key = "#{fetch(:s3_secret_access_key)}"
    # Or, to use a IAM Profile:
    # s3.use_iam_profile = true
    s3.region            = "us-east-1"
    s3.bucket            = "#{fetch(:s3_bucket)}"
    s3.path              = "/files"
end
 archive :app_archive do |archive|
 archive.add '"#{shared_path}/system/public/uploads'
end
 ##
  # Bzip2 [Compressor]
  #
  compress_with Bzip2
 ##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the Wiki for other delivery options.
  # https://github.com/meskyanichi/backup/wiki/Notifiers
  #
  notify_by Mail do |mail|
    mail.on_success           = true
    mail.on_warning           = true
    mail.on_failure           = true
    mail.from                 = "#{fetch(:mailer_username)}"
   mail.to                   = "stuart.watson@unep-wcmc.org"
    mail.address              = "#{fetch(:mailer_address)}"
    mail.port                 = 587
    mail.domain               = "your.host.name"
    mail.user_name            = "#{fetch(:mailer_username)}"
    mail.password             = "#{fetch(:mailer_password)}"
    mail.authentication       = "login"
    mail.encryption           = :starttls
  end
end
EOF

    on roles(:app) do
      execute "mkdir -p #{fetch(:backup_path)}/models"
      upload! StringIO.new(backup_config_files), "#{fetch(:backup_path)}/models/files_#{fetch(:application)}.rb"
    end
  end
end

namespace :config do
  task :setup do
    on roles(:app, :db) do
      execute "/bin/bash -l -c '/home/#{fetch(:deploy_user)}/.rvm/gems/ruby-2.1.3/bin/backup generate:config'"
    end
  end
end

namespace :config do
  task :setup do
    backup_schedule = <<-EOF
every 1.day, :at => '11:30 pm' do
  command "backup perform -t #{fetch(:application)}_files"
  command "backup perform -t #{fetch(:application)}_website_db"
end
EOF

    on roles(:db) do
      execute "mkdir -p #{fetch(:backup_path)}/config"
      upload! StringIO.new(backup_schedule), "#{fetch(:backup_path)}/config/#{fetch(:application)}-schedule.rb"
    end
  end
end

namespace :config do
  task :setup do
    desc "Upload cron schedule file."
    task :upload_cron do
      execute "mkdir -p #{fetch(:backup_path)}/config"
      execute "touch #{fetch(:backup_path)}/config/cron.log"
      upload! StringIO.new(File.read("config/backup/schedule.rb")), "#{fetch(:backup_path)}/config/#{fetch(:application)}-schedule.rb"
    end
  end
end

namespace :config do
  desc "Update crontab with whenever"
  task :setup do
    on roles(:app, :db) do
      execute "cd '#{fetch(:backup_path)}' && /bin/bash -l -c '/home/#{fetch(:deploy_user)}/.rvm/gems/ruby-2.1.3/bin/whenever -f config/#{fetch(:application)}-schedule.rb --update-crontab'"
    end
  end
end

