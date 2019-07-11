# frozen_string_literal: true

module Payments
  class PayoutRequestHandler < ::ApplicationService
    def call
      return if created?

      payout_failed!
    end

    protected

    attr_reader :transaction

    def created?
      raise NotImplementedError, 'Implement #created? method!'
    end

    def payout_failed!
      withdrawal.update(
        transaction_message: error_message,
        status: ::Withdrawal::PENDING
      )

      raise ::Withdrawals::PayoutError, error_message
    end

    def withdrawal
      transaction.withdrawal
    end

    def error_message
      raise NotImplementedError, 'Implement #error_message method!'
    end
  end
end
