# frozen_string_literal: true

module SidekiqScheduler
  class LoadScheduleFromFile < ApplicationService
    # rubocop:disable Security/YAMLLoad
    def call
      YAML.load(read_sidekiq_file)
          .fetch(:schedule, {})
          .transform_values(&method(:append_source_path_to_options))
    end
    # rubocop:enable Security/YAMLLoad

    private

    def read_sidekiq_file
      ERB.new(
        File.read(Rails.root.join(source_path))
      ).result
    end

    def source_path
      Sidekiq.options[:config_file]
    end

    def append_source_path_to_options(options)
      options.deep_merge('source_path' => source_path)
    end
  end
end
