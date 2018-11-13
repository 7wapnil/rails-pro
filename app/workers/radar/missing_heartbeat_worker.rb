module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    def perform
      Radar::Producer.available_producers.each(&:check_subscription_expiration)
    end
  end
end
