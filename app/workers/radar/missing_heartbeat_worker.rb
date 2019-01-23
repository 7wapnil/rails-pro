module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    lock: :until_executed,
                    on_conflict: :log

    def perform(metadata = nil)
      @metadata = metadata
      execute_logged(enqueued_at: enqueued_at) do
        work
      end
    end

    private

    def enqueued_at
      Time.at(@metadata['scheduled_at'])
    end

    def work
      Radar::Producer.all.each(&:unsubscribe_expired!)
    end
  end
end
