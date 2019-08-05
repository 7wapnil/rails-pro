# frozen_string_literal: true

module Radar
  class AliveWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low,
                    retry: 1

    def worker_class
      OddsFeed::Radar::Alive::Handler
    end

    def extra_log_info
      {
        producer_id: Thread.current[:producer_id],
        producer_subscription_state: producer_subscription_state,
        message_subscription_state: Thread.current[:message_subscription_state]
      }
    end

    def producer_subscription_state
      Thread.current[:producer_subscription_state]
    end
  end
end
