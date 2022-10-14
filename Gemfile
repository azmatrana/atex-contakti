source 'https://rubygems.org'

gem 'charlock_holmes', '~> 0.7.6', group: :production # Used for detecting archaic encodings from some random customer email clients.
gem 'oj' # FAST JSON serializer
gem 'oj_mimic_json'
gem 'rails', '4.1.14.1' #github: 'rails/rails', branch: '4-1-stable'
gem 'jbuilder', '~> 1.2'
gem 'less-rails-bootstrap', '~> 3.1.1.1'
gem 'pg'
gem 'devise'
gem 'cancancan', '~> 1.9.2'
gem 'rolify'
gem 'simple_form', '>= 3.1.0.rc2'
gem 'dotenv-rails', '~> 2.0'
gem 'inherited_resources'
gem 'draper', '~> 1.3.1'
gem 'wannabe_bool'
gem 'will_paginate', '~> 3.0.7'
gem 'will_paginate-bootstrap', '~> 1.0.1'
gem 'less-rails'
gem 'sinatra', require: nil
gem 'sidekiq', '3.2.6'
gem 'sidekiq-failures', '~> 0.4.3'
gem 'sidekiq-cron', '~> 0.2', require: false
gem 'sidekiq-unique-jobs', '3.0.2'
gem 'sidekiq-limit_fetch', '2.2.6'
gem 'sidekiq-status'
gem 'aasm'
gem 'paper_trail'
gem 'ruby-ntlm'
gem 'config', '~> 1.0.0.beta3'
gem 'ckeditor'
gem 'simple_calendar', '~> 1.1.0'
gem 'nested_form'
gem 'acts-as-taggable-on', '~> 3.4'
# Javascript-related
gem 'highcharts-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'eco'
gem 'gon'
# Locale-related
gem 'locales_export_import'
gem 'i18n-js', github: 'fnando/i18n-js'
# SMS Sending
gem 'labyrintti', github: 'amoniacou/labyrintti'
gem 'phony_rails'
gem 'phonelib'
# Navigation helper
gem 'navigasmic', github: 'jejacks0n/navigasmic'
# Attachments and PG storage for them
gem 'carrierwave', '~> 0.10.0'
gem 'carrierwave-postgresql', '~> 0.1.4'
gem 'postgresql_lo_streamer', '~> 0.1.2'
# JSON Serializers
gem 'active_model_serializers', '~> 0.8.1'
# AJAX file upload
gem 'remotipart', github: 'dotpromo/remotipart'
# Soft delete
gem 'paranoia', github: 'radar/paranoia', branch: 'rails4'
# Search and sort
gem 'ransack', '~> 1.3.0'
# HTML entitles
gem 'htmlentities', '~> 4.3.2'
# Websokets
gem 'danthes', github: 'dotpromo/danthes'
gem 'puma'
gem 'thin'#, group: :development
gem 'font-awesome-rails'
gem 'select2-rails'
gem 'nokogiri'
gem 'interactor', '~> 3.0'
# For chat transcripts
gem 'redis'
gem "faye-redis"
# Facebook Library
gem "koala", "~> 2.0"
# Store sessions in the database
gem 'activerecord-session_store'

gem 'knockoutjs-rails'

gem 'rake'
gem 'tzinfo-data'
gem 'therubyracer', platforms: :ruby
gem 'rack-cors'

# Sass & Coffee
gem 'sass-rails', '~> 4.0.3'
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'
# gem 'uglifier', '~> 2.7', '>= 2.7.2'
gem 'toastr-rails'
# gem 'uglifier', '~> 4.2'
# Database Backups through dumper.io
gem 'aws-sdk-v1'
gem 'dumper'

# For Payment
gem 'paytrail-client'

# Testing
# To use debugger
# gem 'debugger'
gem 'pry'
gem 'pry-remote'

gem 'poltergeist', github: 'teampoltergeist/poltergeist'
gem 'capybara'
gem 'capybara-screenshot'

group :production do
  gem 'passenger', '~> 5.2.0'
end

group :test, :development do
  gem 'foreman'
  gem 'capistrano', '3.5.0', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-bundler', '~> 1.1.2', require: false
  gem 'capistrano-dotenv-tasks', require: false
  gem 'cap-deploy-tagger', require: false
  gem 'highline', '~> 1.7', '>= 1.7.8' # Prevent password printing
  gem 'slackistrano', require: false
  gem 'annotate'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-expectations'
  gem 'pry-byebug'
  gem 'simplecov', require: false
  gem 'webmock', require: false
  gem 'factory_girl'
  gem 'factory_girl_rails'
  gem 'shoulda', '~> 3.0'
  gem 'turnip'
  gem 'delorean'
  gem 'ffaker'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'konacha'
  gem 'konacha-chai-matchers'
  gem 'phantomjs'
  gem 'launchy'
  gem "better_errors"
  gem "binding_of_caller"
end

group :test do
  gem 'rspec-sidekiq'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do

end

# gem "wit"
# gem 'wit', '~> 7.0'
#gem 'wit', git: 'https://github.com/wit-ai/wit-ruby'

# gem 'wit', '~> 1.0', '>= 1.0.6'
gem "byebug"
gem 'httparty'
gem 'rest-client'