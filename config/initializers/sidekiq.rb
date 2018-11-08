require Rails.root.join('lib/sidekiq/silence_job_logger')
require Rails.root.join('lib/sidekiq_scheduler/silent_scheduler')

Sidekiq::Scheduler.include Sidekiq::SilentScheduler

Sidekiq::Logging.logger = ::MaskedLogStashLoggerFactory.build(type: :stdout)
Sidekiq::Logging.logger.level = ENV['RAILS_LOG_LEVEL'] || Logger::DEBUG

Sidekiq.configure_server do |config|
  config.options[:job_logger] = Sidekiq::SilenceJobLogger
end
