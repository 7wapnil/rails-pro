# frozen_string_literal: true

module Radar
  class OddsChangeWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_high

    def worker_class
      OddsFeed::Radar::OddsChangeHandler
    end

    def extra_log_info
      {
        event_id: Thread.current[:event_id],
        event_producer_id: Thread.current[:event_producer_id],
        message_producer_id: Thread.current[:message_producer_id]
      }
    end
  end
end
