# frozen_string_literal: true

module Payments
  module Fiat
    class Deposit < ::Payments::Operation
      include Payments::Methods

      PAYMENT_METHODS = [
        ::Payments::Methods::CREDIT_CARD,
        ::Payments::Methods::NETELLER,
        ::Payments::Methods::SKRILL,
        ::Payments::Methods::ECO_PAYZ,
        ::Payments::Methods::IDEBIT,
        ::Payments::Methods::PAYSAFECARD
      ].freeze

      BUSINESS_ERRORS = [
        ::Deposits::DepositLimitRestrictionError,
        ::Deposits::DepositAttemptError,
        ::Deposits::CurrencyRuleError,
        ::CustomerBonuses::ActivationError
      ].freeze

      INPUT_ERRORS = [
        ::SafeCharge::InvalidInputError
      ].freeze

      private

      attr_reader :customer_bonus

      def execute_operation
        apply_bonus_code!
        create_entry_request
        assign_request_to_transaction

        return entry_request_failed! if entry_request.failed?

        provider.payment_page_url
      rescue *INPUT_ERRORS => error
        raise ::Payments::GatewayError, error.message
      end

      def apply_bonus_code!
        return unless transaction.bonus

        @customer_bonus = ::CustomerBonuses::Create.call(
          wallet: transaction.wallet,
          bonus: transaction.bonus,
          amount: transaction.amount
        )
      rescue *BUSINESS_ERRORS => error
        raise ::Payments::BusinessRuleError, error.message
      end

      def create_entry_request
        @entry_request = EntryRequests::Factories::Deposit.call(
          transaction: transaction,
          customer_bonus: customer_bonus
        )
      end

      def assign_request_to_transaction
        transaction.id = entry_request.id
      end

      def entry_request_failed!
        raise Payments::BusinessRuleError, entry_request.result['message']
      end
    end
  end
end
