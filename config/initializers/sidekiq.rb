require Rails.root.join('lib/sidekiq/silence_job_logger')
require Rails.root.join('lib/sidekiq_scheduler/scheduler')
require 'sidekiq/processor'

Sidekiq::Logging.logger = ::MaskedLogStashLoggerFactory.build(type: :stdout)

Sidekiq.configure_server do |config|
  config.logger.level = ENV['RAILS_LOG_LEVEL'] || ::Logger::DEBUG
  config.options[:job_logger] = Sidekiq::SilenceJobLogger
end

Sidekiq::Scheduler.include SidekiqScheduler
Sidekiq::Processor.prepend Sidekiq::PatchedProcessor
