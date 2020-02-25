require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Arcanebet
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc

    config.active_job.queue_adapter = :sidekiq

    config.enable_dependency_loading = true

    config.generators do |g|
      g.orm :active_record
    end

    # I18n localization
    config.i18n.load_path += Dir[
      Rails.root.join('config/locales/phraseapp/*.yml')
    ]
    config.i18n.available_locales = %i[en es pt de]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true
    # Protect system formats from overriding via phraseapp
    config.i18n.load_path += Dir[Rails.root.join('config/locales/system/*.yml')]

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib/hash_deep_formatter')
    config.eager_load_paths << Rails.root.join('lib/xml_parser')
    config.eager_load_paths << Rails.root.join('lib/logger')
    config.eager_load_paths << Rails.root.join('lib/errors')
    config.eager_load_paths << Rails.root.join('lib/payments')
    config.eager_load_paths << Rails.root.join('app/workers/sneakers')
    config.eager_load_paths << Rails.root.join('app/graphql/enums')
    config.eager_load_paths << Rails.root.join('app/graphql/unions')

    # Exclude Sneakers workers
    unless Rails.env.test? || ENV['WORKERS']
      config.autoload_paths << Rails.root.join('app/workers')
      config.eager_load_paths
            .delete_if { |path| path.to_s.match?(%r{app/workers}) }

      config.eager_load_paths +=
        Dir.glob(Rails.root.join('app/workers/*/'))
           .reject { |path| path.match?(%r{app/workers/sneakers}) }
    end

    # Settings in config/environments/*
    # take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get post options]
      end
    end

    config.middleware.insert_before 0, Rack::Rewrite do
      rewrite '', '/'
      r301 '/', '/dashboard'
    end

    config.after_initialize do
      Rails.logger = Airbrake::AirbrakeLogger.new(Rails.logger)
      Rails.logger.airbrake_level = Logger::FATAL
    end
  end
end
