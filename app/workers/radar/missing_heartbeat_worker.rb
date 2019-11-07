# frozen_string_literal: true

module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    sidekiq_options queue: :radar_heartbeat,
                    lock: :until_executed,
                    on_conflict: :log,
                    retry: 1

    def perform(metadata = nil)
      @metadata = metadata

      execute_logged(enqueued_at: enqueued_at) do
        Radar::Producer.all.each(&method(:check_heartbeat))
      end
    end

    private

    def enqueued_at
      return unless @metadata && @metadata['scheduled_at']

      Time.at(@metadata['scheduled_at'])
    end

    def check_heartbeat(producer)
      producer.with_lock do
        OddsFeed::Radar::Producers::CheckHeartbeat.call(producer: producer)
      end
    end
  end
end
