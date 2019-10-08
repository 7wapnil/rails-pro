source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

gem 'rails', '~> 5.2.2'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'uglifier', '>= 1.3.0'

gem 'jbuilder', '~> 2.5'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Monkey patches
#
# - sidekiq_scheduler with Sidekiq::SilentScheduler

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'haml-rails', '~> 1.0'
gem 'webpacker', '~> 3.4'
gem 'graphql', '~>1.9'
gem 'graphql-batch'
gem 'goldiloader'
gem 'devise'
gem 'draper'
gem 'jwt'
gem 'simple_form'
gem 'rack-cors', require: 'rack/cors'
gem 'rack-rewrite', '~> 1.5.0'
gem 'activerecord-import'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'ransack', '~> 2.1.1'
gem 'airbrake', '~> 7.3'
gem 'sass-rails'
gem 'sidekiq'
gem 'sidekiq-failures'
gem 'sidekiq-scheduler', '3.0.0'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-limit_fetch'
gem 'graphql-errors'
gem 'redis', '~> 4.0'
gem 'redis-rails'
gem 'redis-rack-cache'
gem 'lograge'
gem 'paranoia', '~> 2.2'
gem 'mongoid', '~> 6.1.0'
gem 'httparty', '~> 0.16.2'
gem 'websocket-driver'
gem 'sneakers', '~> 2.7.0'
gem 'aws-sdk-s3', require: false
gem 'file_validators'
gem 'logstash-event'
gem 'logstash-logger'
gem 'aasm'
gem 'sendgrid-rails', '~> 3.0'
gem 'pagy'
gem 'phonelib'
gem 'cryptocompare'
gem 'recaptcha'
gem 'countries'
gem 'authtrail'
gem 'typhoeus'

gem 'faker', github: 'stympy/faker', branch: 'master', require: false
gem 'factory_bot_rails', require: false

group :production do
  gem 'appsignal'
  gem 'newrelic_rpm'
end

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'rspec-rails', '~> 3.7'
  gem 'rubocop', require: false
  gem 'brakeman', require: false
  gem 'haml_lint', require: false
  gem 'overcommit', require: false
  gem 'rubocop-rspec', require: false
  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'foreman'
end

group :development do
  gem 'rails-erd'
  gem 'web-console', '>= 3.3.0'
  gem 'graphiql-rails'
  gem 'letter_opener'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-brakeman', require: false
  gem 'bullet'
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'rspec-sidekiq'
  gem 'timecop'
  gem 'webmock'
  gem 'database_cleaner' # utils only, not used in rspec
  gem 'action-cable-testing'
end
