module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at)
      super(enqueued_at)

      execute(payload)
      log_success
    rescue StandardError => e
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
