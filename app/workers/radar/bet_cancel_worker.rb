module Radar
  class BetCancelWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed

    def worker_class
      OddsFeed::Radar::BetCancelHandler
    end
  end
end
