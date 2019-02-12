module Radar
  class AliveWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low,
                    retry: 1

    def worker_class
      OddsFeed::Radar::Alive::Handler
    end
  end
end
