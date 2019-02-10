module Radar
  class BetStopWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed

    def worker_class
      OddsFeed::Radar::BetStopHandler
    end
  end
end
