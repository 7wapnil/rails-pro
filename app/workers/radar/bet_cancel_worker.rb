# frozen_string_literal: true

module Radar
  class BetCancelWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low

    def worker_class
      OddsFeed::Radar::BetCancelHandler
    end
  end
end
