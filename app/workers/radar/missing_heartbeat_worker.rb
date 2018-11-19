module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    sidekiq_options lock: :until_executed,
                    on_conflict: :log

    def perform
      Radar::Producer.available_producers.each(&:check_subscription_expiration)
    end
  end
end
