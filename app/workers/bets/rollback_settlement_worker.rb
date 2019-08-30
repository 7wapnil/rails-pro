# frozen_string_literal: true

module Bets
  class RollbackSettlementWorker < ApplicationWorker
    sidekiq_options queue: :default, retry: 0

    def perform(bet_id)
      @bet = Bet.find(bet_id)

      Bets::RollbackSettlement.call(bet: @bet)
    end

    def extra_log_info
      {
        bet_id: @bet.id,
        bet_status: @bet.status,
        settlement_status: @bet.settlement_status,
        void_factor: @bet.void_factor
      }
    end
  end
end
