# frozen_string_literal: true

module SidekiqScheduler
  module PatchedSchedule
    def schedule=(schedule_hash)
      schedule_hash = prepare_schedule(schedule_hash)
      to_remove = get_all_schedules
                  .select { |*, options| filter_deprecated_schedules(options) }
                  .keys

      to_remove.each { |name| remove_schedule(name) }
      schedule_hash.each { |name, job_spec| set_schedule(name, job_spec) }

      @schedule = schedule_hash
    end

    def clean_current_schedules
      get_all_schedules
        .select { |*, options| filter_current_schedules(options) }
        .keys
        .each { |name| remove_schedule(name) }
    end

    private

    def filter_deprecated_schedules(options)
      options['source_path'].blank? || filter_current_schedules(options)
    end

    def filter_current_schedules(options)
      options['source_path'] == self.options[:config_file]
    end
  end
end
