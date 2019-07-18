# frozen_string_literal: true

module Payments
  module Crypto
    class Deposit < ::Payments::Operation
      include Payments::Methods

      PAYMENT_METHODS = [
        ::Payments::Methods::BITCOIN
      ].freeze

      BUSINESS_ERRORS = [
        ::Deposits::DepositLimitRestrictionError,
        ::Deposits::DepositAttemptError,
        ::Deposits::CurrencyRuleError,
        ::CustomerBonuses::ActivationError
      ].freeze

      protected

      def execute_operation
        create_customer_bonus unless !bonus || customer_bonus_active?
        provider.receive_deposit_address
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
