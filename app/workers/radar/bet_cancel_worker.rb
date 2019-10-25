# frozen_string_literal: true

module Radar
  class BetCancelWorker < BaseUofWorker
    sidekiq_options queue: :radar_odds_feed_low

    def worker_class
      OddsFeed::Radar::BetCancelHandler
    end

    def extra_log_info
      {
        start_time: payload.dig('bet_cancel', 'start_time'),
        end_time: payload.dig('bet_cancel', 'end_time')
      }
    end
  end
end
