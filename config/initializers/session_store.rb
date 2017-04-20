# Be sure to restart your server when you modify this file.

#OnlineReportingTool::Application.config.session_store :cookie_store, key: '_report_manager_session'
OnlineReportingTool::Application.config.session_store :redis_session_store, {
  key: '_report_manager_session',
  redis: {
    expire_after: 3.weeks,
    key_prefix: 'online_reporting_tool:session:',
    url: Rails.application.secrets.redis['url']
  }
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# OrtConfigApp::Application.config.session_store :active_record_store
