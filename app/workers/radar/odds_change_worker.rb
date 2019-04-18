# frozen_string_literal: true

module Radar
  class OddsChangeWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_high

    def worker_class
      OddsFeed::Radar::OddsChangeHandler
    end
  end
end
