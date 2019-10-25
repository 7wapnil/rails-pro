# frozen_string_literal: true

module Radar
  class RollbackBetCancelWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low, retry: 0

    def worker_class
      OddsFeed::Radar::RollbackBetCancelHandler
    end

    def extra_log_info
      {
        start_time: payload.dig('rollback_bet_cancel', 'start_time'),
        end_time: payload.dig('rollback_bet_cancel', 'end_time')
      }
    end
  end
end
