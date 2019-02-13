module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at)
      Thread.current[:event_id] = event_id_scan(payload)
      execute_logged(enqueued_at: enqueued_at) do
        execute(payload)
      end
    end

    def worker_class
      raise ::NotImplementedError
    end

    private

    def event_id_scan(payload)
      result = payload.scan(Regexp.new('event_id="([^"]*)"'))
      return '' if result.empty?

      result[0][0]
    end

    def execute(payload)
      worker_class.new(XmlParser.parse(payload)).handle
    end
  end
end
