# frozen_string_literal: true

module Bets
  class SettlementWorker < ApplicationWorker
    sidekiq_options queue: :default, retry: 0

    def perform(bet_id, void_factor, result)
      @bet = Bet.find(bet_id)
      @void_factor = void_factor
      @result = result

      Bets::Settle.call(bet: @bet, void_factor: void_factor, result: result)
    end

    def extra_log_info
      {
        bet_id: @bet.id,
        bet_status: @bet.status,
        void_factor: @void_factor,
        result: @result
      }
    end
  end
end
