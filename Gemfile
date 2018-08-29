source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

gem 'rails', '~> 5.2.0'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'

gem 'jbuilder', '~> 2.5'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'haml-rails', '~> 1.0'
gem 'webpacker', '~> 3.4'
gem 'graphql', '~>1.8'
gem 'goldiloader'
gem 'devise'
gem 'jwt'
gem 'simple_form'
gem 'rack-cors', require: 'rack/cors'
gem 'activerecord-import'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'ransack'
gem 'airbrake', '~> 7.3'
gem 'sidekiq'
gem 'graphql-errors'
gem 'redis', '~> 4.0'
gem 'redis-rails'
gem 'redis-rack-cache'
gem 'lograge'
gem 'newrelic_rpm'
gem 'paranoia', '~> 2.2'
gem 'mongoid', '~> 6.1.0'
gem 'httparty', '~> 0.16.2'
gem 'websocket-driver'
gem 'sneakers', '~> 2.7.0'
gem 'aws-sdk-s3', require: false

# To be moved back to development and test group
gem 'faker', github: 'stympy/faker', branch: 'master'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 3.7'
  gem 'factory_bot_rails'
  gem 'rubocop', require: false
  gem 'brakeman', require: false
  gem 'awesome_print'
  gem 'pry-rails'
end

group :development do
  gem 'rails-erd'
  gem 'web-console', '>= 3.3.0'
  gem 'graphiql-rails'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-brakeman', require: false
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'rspec-sidekiq'
  gem 'timecop'
  gem 'webmock'
end
