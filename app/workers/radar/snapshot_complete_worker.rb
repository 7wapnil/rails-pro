module Radar
  class SnapshotCompleteWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low

    def worker_class
      OddsFeed::Radar::SnapshotCompleteHandler
    end
  end
end
