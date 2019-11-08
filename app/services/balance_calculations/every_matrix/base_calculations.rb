# frozen_string_literal: true

module BalanceCalculations
  module EveryMatrix
    class BaseCalculations < ApplicationService
      MONEY_PRECISION = 2
      REAL_MONEY_ONLY_RATIO = 1.0

      delegate :wallet, to: :transaction
      delegate :amount, to: :wallet, prefix: true
      delegate :customer_bonus, :real_money_balance, :bonus_balance,
               to: :wallet, allow_nil: true

      def initialize(transaction:)
        @transaction = transaction
      end

      def call
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end

      private

      attr_reader :transaction

      def calculated_real_money_amount
        @calculated_real_money_amount ||= (transaction.amount * ratio)
                                          .round(MONEY_PRECISION)
      end

      def with_casino_bonus?
        customer_bonus&.active? && customer_bonus&.casino?
      end

      def ratio
        return REAL_MONEY_ONLY_RATIO unless with_casino_bonus?

        real_money_balance / wallet_amount
      end

      def calculated_bonus_amount
        transaction.amount - calculated_real_money_amount
      end
    end
  end
end
