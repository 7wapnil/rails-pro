# frozen_string_literal: true

module Payments
  class Withdraw < Operation
    include Methods

    PAYMENT_METHODS = [
      *::Payments::Fiat::Payout::PAYMENT_METHODS,
      *::Payments::Crypto::Payout::PAYMENT_METHODS
    ].freeze

    delegate :customer, to: :transaction

    def execute_operation
      create_entry_request!

      return entry_request_failed! if entry_request.failed?

      process_entry_request
    end

    private

    def create_entry_request!
      @entry_request = EntryRequests::Factories::Withdrawal.call(
        transaction: transaction
      )
    end

    def entry_request_failed!
      error_data = entry_request.result
                                .values_at('message', 'attribute')
                                .compact

      raise Payments::BusinessRuleError.new(*error_data)
    end

    def process_entry_request
      EntryRequests::WithdrawalWorker.perform_async(entry_request.id)
    end
  end
end
