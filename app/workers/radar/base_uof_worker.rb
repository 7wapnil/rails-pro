module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, serialized_profiler = nil)
      populate_event_id_to_thread(event_id_scan(payload))
      profiler = OddsFeed::MessageProfiler.deserialize(serialized_profiler)
      profiler.log_state(:worker_started_at)
      execute_logged(enqueued_at: enqueued_at) do
        execute(payload, profiler: profiler)
      end
    end

    def worker_class
      raise ::NotImplementedError
    end

    private

    def execute(payload, profiler: nil)
      worker_class.new(
        XmlParser.parse(payload),
        profiler
      ).handle
    end
  end
end
