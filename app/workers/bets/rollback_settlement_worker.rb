# frozen_string_literal: true

module Bets
  class RollbackSettlementWorker < ApplicationWorker
    sidekiq_options queue: :default, retry: 0

    def perform(bet_leg_id)
      @bet_leg = BetLeg.includes(:bet).find(bet_leg_id)

      Bets::RollbackSettlement.call(bet_leg: @bet_leg)
    end

    def extra_log_info
      {
        bet_id: @bet_leg.bet.id,
        bet_status: @bet_leg.bet.status,
        settlement_status: @bet_leg.bet.settlement_status,
        void_factor: @bet_leg.bet.void_factor
      }
    end
  end
end
