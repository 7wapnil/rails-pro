module Radar
  class FixtureChangeWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed

    def worker_class
      OddsFeed::Radar::FixtureChangeHandler
    end
  end
end
