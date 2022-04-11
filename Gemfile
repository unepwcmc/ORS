source 'https://rubygems.org'

gem 'rails', '3.2.22'
gem 'rake', '10.0.3'

gem 'pg'
gem 'foreigner'

gem 'json'

gem 'jquery-rails', '2.1.4'
gem 'jquery-ui-rails', '2.0.1'
gem 'jqgrid-jquery-rails', '~> 4.4.001'
gem 'tinymce-rails', '4.0'
gem 'tinymce-rails-langs', '~>4.2'
gem 'jstree-rails', :git => 'git://github.com/tristanm/jstree-rails.git'
gem "gritter", "1.1.0"
gem 'tooltipster-rails', '~> 3.2.6'
gem 'jquery-tablesorter', '~> 1.16.3'
gem 'jquery-placeholder-rails', '~> 2.0.7'
gem 'jquery-cookie-rails', '~> 1.3.1.1'
gem "select2-rails"
gem 'authlogic'
gem 'fastercsv'
gem 'cancan'
gem 'acts-as-taggable-on'
gem 'paperclip', '~> 4.2.1'
gem 'formtastic'
gem 'sanitize'
gem 'enumerate_it'
gem 'awesome_nested_set'
gem "font-awesome-rails"
gem 'faker'

#gem 'pdf-reader', :require => 'pdf/reader'
#gem 'Ascii85', :require => 'ascii85'
gem 'prawn'
gem 'htmlentities'
gem 'axlsx', git: 'https://github.com/randym/axlsx', branch: 'release-3.0.0'
gem 'nokogiri', '~> 1.13.4'

gem 'redis'
gem 'redis-session-store'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'sinatra', :require => nil
gem 'mocha'

gem 'dotenv-rails'
gem 'rails-secrets'

gem 'appsignal'

gem 'traco'

gem "recaptcha", require: "recaptcha/rails"

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.2.0"
  gem 'coffee-rails', "~> 3.2.0"
  gem 'uglifier'
end

group :production, :staging do
  gem 'newrelic_rpm'
end

group :development, :test do
  gem 'byebug'
  gem 'time_bandits'
  gem 'ruby-prof'
end

group :development do
  gem 'capistrano', '~> 3.11.0', require:false
  gem 'capistrano-multiconfig', '~> 3.1.0',require:false
  gem 'capistrano-rails', require:false
  gem 'capistrano-bundler', require:false
  gem 'capistrano-rvm', require:false
  gem 'capistrano-sidekiq'
  gem 'capistrano-passenger'
  gem 'capistrano-local-precompile', '~> 1.2.0', require: false
  gem 'annotate'
  gem 'sexy_relations', '~> 1.0.4'
  gem 'rubocop', require: false
  gem 'quiet_assets'
end

group :test do
  gem "factory_girl_rails", "~> 4.2.0"
  gem 'database_cleaner'
  gem 'minitest-rails', '~>1.0'
  gem 'shoulda-context'
end

gem 'test-unit', '~> 3.1' # annoyingly, rails console won't start without it in staging / production
