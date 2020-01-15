# frozen_string_literal: true

module EveryMatrix
  module Requests
    class RollbackSettlementService < ApplicationService
      def initialize(transaction)
        @transaction = transaction
        @customer_bonus = transaction.wager&.customer_bonus
      end

      def call
        return true unless bonus?

        lose_bonus! if lose_bonus? && no_pending_casino_wagers?

        release_pending_wagers! unless lose_bonus?

        update_round_status!

        true
      end

      private

      attr_reader :transaction, :customer_bonus

      def lose_bonus!
        ::CustomerBonuses::Deactivate.call(
          bonus: customer_bonus,
          action: ::CustomerBonuses::Deactivate::LOSE
        )
      end

      def lose_bonus?
        !customer_bonus.wallet.bonus_balance.positive? &&
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

      def update_round_status!
        transaction.game_round.rolled_back!
      end
    end
  end
end
