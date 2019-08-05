# frozen_string_literal: true

Sidekiq.configure_server do |config|
  # Remove default Sidekiq scheduler startup hook
  startup_hooks = config.options.dig(:lifecycle_events, :startup)
  startup_hooks.delete_if do |procedure|
    procedure.source_location.first.include?('lib/sidekiq-scheduler.rb')
  end

  config.on(:startup) do
    Sidekiq.schedule = SidekiqScheduler::LoadScheduleFromFile.call

    schedule_manager = SidekiqScheduler::Manager.new(config.options)

    config.options[:schedule_manager] = schedule_manager
    config.options[:schedule_manager].start
  end

  config.on(:shutdown) { Sidekiq.clean_current_schedules }
end
