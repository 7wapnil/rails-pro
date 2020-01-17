# frozen_string_literal: true

module EveryMatrix
  module Requests
    class BaseSettlementService < ApplicationService
      def initialize(transaction)
        @transaction = transaction
        @customer_bonus = transaction.customer_bonus
        @play_item = transaction&.play_item
      end

      private

      attr_reader :transaction, :customer_bonus, :play_item

      def bonus?
        customer_bonus&.active? &&
          customer_bonus&.casino?
      end

      def complete_bonus!
        ::CustomerBonuses::Complete.call(customer_bonus: customer_bonus)

        true
      end

      def complete_bonus?
        customer_bonus.rollover_balance <= 0
      end

      def positive_bonus_balance?
        customer_bonus.wallet.bonus_balance.positive?
      end

      def lose_bonus!
        ::CustomerBonuses::Deactivate.call(
          bonus: customer_bonus,
          action: ::CustomerBonuses::Deactivate::LOSE
        )
      end

      def lose_bonus?
        !positive_bonus_balance? &&
          customer_bonus.active? &&
          customer_bonus.rollover_balance.positive? &&
          no_pending_sportsbook_bets?
      end

      def release_pending_wagers!
        EveryMatrix::Wager
          .where(customer_bonus: customer_bonus)
          .pending_bonus_loss
          .each(&:finish!)
      end

      def no_pending_sportsbook_bets?
        return true unless customer_bonus.sportsbook?

        Bet
          .pending
          .where(customer_bonus: customer_bonus)
          .none?
      end
    end
  end
end
