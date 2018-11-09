require Rails.root.join('lib/sidekiq/silence_job_logger')

Sidekiq::Logging.logger = ::MaskedLogStashLoggerFactory.build(type: :stdout)

Sidekiq.configure_server do |config|
  config.logger.level = ENV['SIDEKIQ_LOG_LEVEL'] || ::Logger::DEBUG
  config.options[:job_logger] = Sidekiq::SilenceJobLogger
end
