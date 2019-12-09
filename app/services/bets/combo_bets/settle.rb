# frozen_string_literal: true

module Bets
  module ComboBets
    class Settle < ::Bets::Settle
      private

      def settle!
        settle_bet_leg!
        return if !lost? && unsettled_bet_legs?

        settle_bet!
        perform_payout!
        settle_customer_bonus!
      end

      def lock_important_entities!
        bet.lock!
        bet_leg.lock!
        customer_bonus&.lock!
      end

      def settle_bet_leg!
        bet_leg.update!(
          settlement_status: raw_settlement_status,
          void_factor: raw_void_factor
        )
      end

      def unsettled_bet_legs?
        bet.bet_legs
           .any? do |leg|
             next false if leg.id == bet_leg.id

             leg.settlement_status.nil? && leg.status.nil?
           end
      end

      def settlement_status
        return Bet::LOST if lost?
        return Bet::VOIDED if bet.bet_legs
                                 .all? do |leg|
                                   next false if leg.id == bet_leg.id &&
                                                 !bet_leg.voided?

                                   leg.voided? || leg.cancelled_by_system?
                                 end

        Bet::WON
      end

      def lost?
        raw_settlement_status == Bet::LOST
      end

      def voided?
        raw_settlement_status == Bet::VOIDED
      end

      def void_factor
        bet_leg_void_factor if lost?
      end
    end
  end
end
