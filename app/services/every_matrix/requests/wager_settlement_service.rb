# frozen_string_literal: true

module EveryMatrix
  module Requests
    class WagerSettlementService < ApplicationService
      def initialize(transaction)
        @transaction = transaction
        @customer_bonus = transaction.customer_bonus
        @play_item = transaction.play_item
      end

      def call
        return unless customer_bonus.active? && customer_bonus.casino?

        recalculate_bonus_rollover

        return complete_bonus! if complete_bonus?

        lose_bonus! if lose_bonus?

        true
      end

      private

      attr_reader :transaction, :customer_bonus, :play_item

      def recalculate_bonus_rollover
        customer_bonus.with_lock do
          customer_bonus.rollover_balance -= rollover_amount
          customer_bonus.save!
        end

        customer_bonus.reload
      end

      def rollover_amount
        [
          customer_bonus.max_rollover_per_spin,
          transaction.amount * play_item.bonus_contribution
        ].min
      end

      def complete_bonus!
        ::CustomerBonuses::Complete.call(customer_bonus: customer_bonus)
      end

      def lose_bonus!
        ::CustomerBonuses::Deactivate.call(
          bonus: customer_bonus,
          action: ::CustomerBonuses::Deactivate::LOSE
        )
      end

      def complete_bonus?
        customer_bonus.rollover_balance <= 0
      end

      def lose_bonus?
        customer_bonus.wallet.bonus_balance <= 0 &&
          customer_bonus.active? &&
          customer_bonus.rollover_balance.positive? &&
          Bet.pending.where(customer_bonus: customer_bonus).none?
      end
    end
  end
end
