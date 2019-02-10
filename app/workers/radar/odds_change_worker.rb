module Radar
  class OddsChangeWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed

    def worker_class
      OddsFeed::Radar::OddsChangeHandler
    end
  end
end
