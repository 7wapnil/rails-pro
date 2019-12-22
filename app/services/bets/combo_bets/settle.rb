# frozen_string_literal: true

module Bets
  module ComboBets
    class Settle < ::Bets::Settle
      private

      def settle!
        settle_bet_leg!
        return if already_lost_bet? || !lost? && unsettled_bet_legs?
        return lose_bet_without_settlement! if lose_with_pending_bet_legs?

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

      def already_lost_bet?
        bet.lost? && bet.bet_legs.any?(&:lost?)
      end

      def unsettled_bet_legs?
        bet.bet_legs
           .any? do |leg|
             next false if leg.id == bet_leg.id

             leg.settlement_status.nil? && !leg.cancelled_by_system?
           end
      end

      def lose_with_pending_bet_legs?
        lost? &&
          bet.pending_manual_settlement? &&
          bet.bet_legs.any?(&:pending_manual_settlement?)
      end

      def lose_bet_without_settlement!
        bet.resend_to_manual_settlement!(settlement_status: Bet::LOST)
        settle_customer_bonus!
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
