# frozen_string_literal: true

module Payments
  module CoinsPaid
    class Deposit < Operation
      PROVIDER = ::Payments::CoinsPaid::Provider

      BUSINESS_ERRORS = [
        ::Deposits::DepositLimitRestrictionError,
        ::Deposits::DepositAttemptError,
        ::Deposits::CurrencyRuleError,
        ::CustomerBonuses::ActivationError
      ].freeze

      protected

      def execute_operation
        create_customer_bonus unless bonus.nil? || customer_bonus_active?
        PROVIDER.new.payment_page_url(transaction)
      end

      private

      delegate :wallet, :bonus, to: :transaction
      delegate :customer_bonus, to: :wallet

      def create_customer_bonus
        CustomerBonuses::Create.call(
          wallet: transaction.wallet,
          bonus: transaction.bonus,
          amount: transaction.amount
        )
      rescue *BUSINESS_ERRORS => error
        raise ::Payments::BusinessRuleError, error.message
      end

      def customer_bonus_active?
        customer_bonus&.initial? || customer_bonus&.active?
      end
    end
  end
end
