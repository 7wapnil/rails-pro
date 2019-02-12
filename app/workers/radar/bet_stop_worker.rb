module Radar
  class BetStopWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_high

    def worker_class
      OddsFeed::Radar::BetStopHandler
    end
  end
end
