module Bets
  class SettlementWorker < ApplicationWorker
    def perform(bet_id)
      bet = Bet.find(bet_id)

      Bets::Settlement::Proceed.call(bet: bet)
    end
  end
end
