# frozen_string_literal: true

module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at = nil)
      populate_message_info_to_thread(payload)

      @payload = XmlParser.parse(payload)

      execute_logged(enqueued_at: enqueued_at) do
        execute
      end
    end

    def worker_class
      raise ::NotImplementedError
    end

    private

    attr_reader :payload

    def execute
      worker_class.new(payload).handle
    end
  end
end
