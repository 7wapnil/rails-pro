module Radar
  class BaseUofWorker < ApplicationWorker
    include OddsFeed::FlowProfiler
    sidekiq_options retry: 3

    def perform(payload, serialized_profiler = nil)
      populate_event_id_to_thread(event_id_scan(payload))
      if serialized_profiler
        create_flow_profiler(serialized_attributes: serialized_profiler)
      end
      flow_profiler.trace_profiler_event(:worker_started_at)
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
