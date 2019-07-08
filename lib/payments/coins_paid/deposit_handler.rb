# frozen_string_literal: true

module Payments
  module CoinsPaid
    class DepositHandler < ApplicationService
      def initialize(transaction:, customer_bonus:)
        @transaction = transaction
        @customer_bonus = customer_bonus
      end

      def call
        validate_transaction!
        create_entry_request

        entry_request_failed! if entry_request.failed?

        entry_request
      end

      private

      attr_reader :transaction, :customer_bonus, :entry_request

      def validate_transaction!
        return if transaction.valid?

        raise Payments::InvalidTransactionError, transaction
      end

      def create_entry_request
        @entry_request = EntryRequests::Factories::Deposit.call(
          wallet: transaction.wallet,
          amount: transaction.amount,
          mode: transaction.method,
          customer_bonus: customer_bonus,
          external_id: transaction.external_id
        )
      end

      def entry_request_failed!
        raise Payments::BusinessRuleError, entry_request.result['message']
      end
    end
  end
end
