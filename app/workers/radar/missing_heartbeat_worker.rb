module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    lock: :until_executed,
                    on_conflict: :log

    def perform
      super()

      Radar::Producer.available_producers.each(&:check_subscription_expiration)
    end
  end
end
