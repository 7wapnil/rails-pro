# frozen_string_literal: true

module Bets
  module SingleBet
    class Settle < ::Bets::Settle
      private

      alias_method :settlement_status, :raw_settlement_status
      alias_method :void_factor, :bet_leg_void_factor

      def settle!
        settle_bet_leg!
        settle_bet!
        perform_payout!
        settle_customer_bonus!
      end

      def lock_important_entities!
        bet.lock!
        customer_bonus&.lock!
      end

      def settle_bet_leg!
        bet_leg.update!(
          settlement_status: settlement_status,
          void_factor: void_factor
        )
      end
    end
  end
end
