# Online Reporting Tool

## User guide

A user guide for the application is available from the repository's doc folder.

## Development

### Installing locally

1 Install necessary software

This branch uses the following software:

* Ruby 2.2.3 install as system wide version or using one Ruby Version Manager like [rvm](https://rvm.io/)
or [rbenv](https://github.com/sstephenson/rbenv).
* [PostgreSQL](http://www.postgresql.org/) 9.4
* [Redis](http://redis.io/): "Redis is an open source, BSD licensed, advanced key-value store",
and is used in this application to store background jobs
* [ImageMagick](http://www.imagemagick.org) used by paperclip to scale image attachments
* Rails 3, installed as a gem via bundler (see point 5)

2 Clone Github Repository into your desired directory

````
    git clone https://github.com/unepwcmc/ORS
````

3 Go into the application folder and switch to Ruby 2.0 branch

````
    cd ORS
    git checkout master
````

4 Copy config/database.yml.example to config/database.yml and update with your local details

5 Install necessary gems using Bundle (you will need to have the [bundler gem](https://github.com/bundler/bundler) installed)

````
    bundle install
````

Note: One of the gems that this command installs is **capybara-webkit**.
This gem depends on QT4, if the bundle command fails because of this gem please refer to [this page](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit) for help addressing this.
After installing this software run "bundle install" again.

6 Set up your Postgres database, User Roles and one Admin user to get you started

````
    rake db:create
    rake db:migrate
    rake db:seed
````

7 Fire up your server

````
    rails server
````    

8 And visit the home page in:

````
    http://localhost:3000
````

Database backups can be found on WCMC Dropbox (ask for a sample if you need one), and can be imported using:

    psql -U postgres ort_development -f backup.sql

#### Background jobs use the [sidekiq gem](https://github.com/mperham/sidekiq) which requires [Redis](http://redis.io/)

Sidekiq workers can be started using:

    bundle exec sidekiq -C config/sidekiq.yml

sidekiq-status is installed and available at /sidekiq.

### Testing

Integration tests are powered by Capybara and can be run with:

    rake test:integration

## Other notes

### Uploaded files locations

#### User added files

* Questionnaire header: `PROJECT_PATH/public/system/headers/:questionnaire_id`
* Answer document: `PROJECT_PATH/private/answer_docs/:questionnaire_id/answer_documents/:user_id/:answer_id/`
* LoopSource source `file: PROJECT_PATH/public/system/sources/:source_file_id`

#### System generated files

* Questionnaire PDF for a user: `PROJECT_PATH/private/questionnaires/:questionnaire_id/users/:user_id/`
* Questionnaire CSV: `PROJECT_PATH/private/questionnaires/:questionnaire_id/`

## Deployment

### Storing sensitive configuration parameters
We store instance-specific configuration parameters (such as secret token, mailer details) in .env files loaded via [dotenv gem](https://github.com/bkeepers/dotenv).

Those values are then made available to the application via [rails-secret gem](https://github.com/pixeltrix/rails-secrets) and can beaccessed in a Rails 4 fashion.

### Exception notifications

[exception_notification gem](https://github.com/smartinez87/exception_notification) is configured to send emails & slack messages in staging & production environments.

### Capistrano

We're using a gem called capistrano-multiconfig which includes the ability to have different deploy/production.rb and deploy/staging.rb files for different applications with the same deploy.

For example:
```
.
├── bern-ort
│   ├── production.rb
│   └── staging.rb
├── cites-ort
│   ├── production.rb
│   └── staging.rb
├── cms-ort
│   ├── production.rb
│   └── staging.rb
└── icca-ort
    ├── production.rb
    └── staging.rb
```

So we can then do something like

`cap bern-ort:staging deploy`
`cap cms-ort:staging deploy`
