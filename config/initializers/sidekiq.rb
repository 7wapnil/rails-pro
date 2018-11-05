require Rails.root.join('lib/sidekiq/silence_job_logger')
require Rails.root.join('lib/sidekiq_scheduler/silent_scheduler')

Sidekiq::Scheduler.include Sidekiq::SilentScheduler

Sidekiq::Logging.logger = ::MaskedLogStashLoggerFactory.build(type: :stdout)

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(
      File.expand_path('../sidekiq_scheduler.yml', __dir__)
    )
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
  config.options[:job_logger] = SilenceJobLogger
end
