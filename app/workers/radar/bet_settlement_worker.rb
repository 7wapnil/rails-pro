module Radar
  class BetSettlementWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low,
                    retry: 0

    def worker_class
      OddsFeed::Radar::BetSettlementHandler
    end
  end
end
