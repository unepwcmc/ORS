Sidekiq.configure_server do |config|
  config.redis = {
    :namespace => Rails.application.secrets.redis['namespace'],
    :url => Rails.application.secrets.redis['url']
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    :namespace => Rails.application.secrets.redis['namespace'],
    :url => Rails.application.secrets.redis['url']
  }
end
