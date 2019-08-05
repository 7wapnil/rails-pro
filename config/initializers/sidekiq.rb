require Rails.root.join('lib/sidekiq/silence_job_logger')
require Rails.root.join('lib/sidekiq_scheduler/scheduler')
require Rails.root.join('lib/sidekiq_scheduler/configure_server')
require 'sidekiq/processor'

Sidekiq::Logging.logger = ::MaskedLogStashLoggerFactory.build(type: :stdout)

Sidekiq.configure_server do |config|
  config.logger.level = ENV['RAILS_LOG_LEVEL'] || ::Logger::DEBUG
  config.options[:job_logger] = Sidekiq::SilenceJobLogger

  config.on(:startup) do
    SidekiqScheduler::Scheduler
      .instance
      .rufus_scheduler_options = { max_work_threads: 10 }
  end
end

Sidekiq.extend SidekiqScheduler::PatchedSchedule
Sidekiq::Scheduler.include SidekiqScheduler
Sidekiq::Processor.prepend Sidekiq::PatchedProcessor
