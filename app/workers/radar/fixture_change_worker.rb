module Radar
  class FixtureChangeWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_high

    def worker_class
      OddsFeed::Radar::FixtureChangeHandler
    end
  end
end
