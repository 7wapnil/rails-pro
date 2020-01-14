# frozen_string_literal: true

module EveryMatrix
  module Requests
    class ResultSettlementService < ApplicationService
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

      def lose_bonus!
        Deactivate.call(
          bonus: customer_bonus,
          action: Deactivate::LOSE
        )
      end

      def lose_bonus?
        !customer_bonus.wallet.bonus_balance.positive? &&
          customer_bonus.active? &&
          customer_bonus.rollover_balance.positive? &&
          no_pending_sportsbook_bets?
      end

      def release_pending_wagers!
        customer_bonus.wagers.pending_bonus_loss.each(&:finish!)
      end

      def update_round_status!
        return transaction.game_rund.lost! if transaction.amount.zero?

        transaction.game_round.won!
      end
    end
  end
end
