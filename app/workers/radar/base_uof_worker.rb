module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at)
      execute_logged(enqueued_at: enqueued_at) do
        execute(payload)
      end
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
