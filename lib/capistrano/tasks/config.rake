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
