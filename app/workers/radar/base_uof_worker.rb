module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, profiler)
      populate_event_id_to_thread(event_id_scan(payload))
      execute_logged(enqueued_at: enqueued_at) do
        execute(payload, profiler)
      end
    end

    def worker_class
      raise ::NotImplementedError
    end

    private

    def execute(payload, profiler)
      worker_class.new(XmlParser.parse(payload), profiler).handle
    end
  end
end
