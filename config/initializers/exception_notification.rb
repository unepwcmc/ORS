if Rails.env.staging? || Rails.env.production?
  require 'exception_notification/rails'
  require 'exception_notification/sidekiq'
  require 'yaml'

  ExceptionNotification.configure do |config|
    # Ignore additional exception types.
    # ActiveRecord::RecordNotFound, AbstractController::ActionNotFound and ActionController::RoutingError are already added.
    config.ignored_exceptions += %w{ActionController::InvalidAuthenticityToken}

    # Adds a condition to decide when an exception must be ignored or not.
    # The ignore_if method can be invoked multiple times to add extra conditions.
    # config.ignore_if do |exception, options|
    #   not Rails.env.production? || Rails.env.staging?
    # end

    # Notifiers =================================================================

    # Email notifier sends notifications by email.
    config.add_notifier :email, {
      :email_prefix => "[ORS #{Rails.env}: #{`hostname`}] ",
      :sender_address => %{"ORS Exception Notifier" <no-reply@unep-wcmc.org>},
      :exception_recipients => Rails.application.secrets.exception_notification_email
    }

    secrets = YAML.load(File.open('config/secrets.yml'))

    config.add_notifier :slack, {
      :webhook_url => Rails.application.secrets.exception_notification_slack_webhook,
      :channel => "#online-reporting-tool",
      :username => "ORS #{Rails.env}: #{`hostname`}"
    }
  end
end
