module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    lock: :until_executed,
                    on_conflict: :log

    def perform
      Radar::Producer.all.each(&:unsubscribe_expired!)
    end
  end
end
