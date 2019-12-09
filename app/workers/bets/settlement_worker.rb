# frozen_string_literal: true

module Bets
  class SettlementWorker < ApplicationWorker
    sidekiq_options queue: :default, retry: 0

    def perform(bet_leg_id, void_factor, result)
      @bet_leg = BetLeg.find(bet_leg_id)
      @void_factor = void_factor
      @result = result

      settlement_service.call(bet_leg: @bet_leg,
                              void_factor: void_factor,
                              result: result)
    end

    def settlement_service
      return Bets::ComboBets::Settle if @bet_leg.bet.combo_bets?

      Bets::SingleBet::Settle
    end

    def extra_log_info
      {
        bet_leg_id: @bet_leg.id,
        bet_status: @bet.status,
        void_factor: @void_factor,
        result: @result
      }
    end
  end
end
