# frozen_string_literal: true

module Radar
  class RollbackBetCancelWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_high, retry: 0

    def worker_class
      OddsFeed::Radar::RollbackBetCancelHandler
    end
  end
end
