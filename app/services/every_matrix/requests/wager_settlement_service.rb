# frozen_string_literal: true

module EveryMatrix
  module Requests
    class WagerSettlementService < BaseSettlementService
      def call
        return true unless bonus?

        recalculate_bonus_rollover

        return complete_bonus! if complete_bonus?
        return mark_wager_pending! if pending_lost_bonus?

        true
      end

      private

      def recalculate_bonus_rollover
        customer_bonus.with_lock do
          customer_bonus.rollover_balance -= rollover_amount
          customer_bonus.save!
        end

        customer_bonus
      end

      def rollover_amount
        [
          customer_bonus.max_rollover_per_spin,
          transaction.amount * play_item.bonus_contribution
        ].min
      end

      def mark_wager_pending!
        transaction.pending_bonus_loss!

        true
      end

      def pending_lost_bonus?
        !customer_bonus.wallet.bonus_balance.positive? &&
          customer_bonus.active? &&
          customer_bonus.rollover_balance.positive? &&
          no_pending_sportsbook_bets? &&
          no_pending_casino_wagers?
      end

      def positive_bonus_balance?
        customer_bonus.wallet.bonus_balance.positive?
      end

      def no_pending_sportsbook_bets?
        return true unless customer_bonus.sportsbook?

        Bet
          .pending
          .where(customer_bonus: customer_bonus)
          .none?
      end

      def no_pending_casino_wagers?
        return true unless customer_bonus.casino?

        EveryMatrix::Wager
          .pending_bonus_loss
          .where(customer_bonus: customer_bonus)
          .none?
      end
    end
  end
end
