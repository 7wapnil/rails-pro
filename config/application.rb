require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Arcanebet
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.time_zone = 'Tallinn'

    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      g.orm :active_record
    end

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib/hash_deep_formatter')
    config.eager_load_paths << Rails.root.join('lib/xml_parser')
    config.eager_load_paths << Rails.root.join('lib/logger')
    config.eager_load_paths << Rails.root.join('lib/errors')
    config.eager_load_paths << Rails.root.join('app/workers/sneakers')

    # Exclude Sneakers workers
    unless ENV['WORKERS']
      config
        .eager_load_paths
        .reject! { |path| path.to_s.match?(%r{app/workers}) }

      config
        .eager_load_paths += Dir.glob(Rails.root.join('app/workers/*'))
                                .reject { |path| path.match?(%r{/sneakers}) }
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

    config.after_initialize do
      Rails.logger = Airbrake::AirbrakeLogger.new(Rails.logger)
      Rails.logger.airbrake_level = Logger::ERROR
    end
  end
end
