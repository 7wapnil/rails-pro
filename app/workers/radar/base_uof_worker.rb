# frozen_string_literal: true

module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at = nil)
      populate_message_info_to_thread(payload)

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
