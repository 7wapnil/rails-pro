module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at)
      @enqueued_at = enqueued_at
      populate_enqueued_at_to_thread

      execute(payload)
      log_success
    rescue StandardError => e
      # NB: Main job logging for errors is disabled here:
      # `lib/sidekiq/patched_processor.rb:9`
      log_failure e
      raise e
    end

    def worker_class
      raise ::NotImplementedError
    end

    private

    def execute(payload)
      worker_class.new(XmlParser.parse(payload)).handle
    end
  end
end
