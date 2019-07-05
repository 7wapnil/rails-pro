# frozen_string_literal: true

module Payments
  class PayoutResponseHandler < ::ApplicationService
    def call
      return if created?

      withdrawal.update(
        transaction_message: error_message,
        status: ::Withdrawal::PENDING
      )
      payout_failed!
    end

    protected

    attr_reader :response

    def error_message
      raise NotImplementedError, 'Implement #error_message method!'
    end

    def request_id
      raise NotImplementedError, 'Implement #request_id method!'
    end

    def withdrawal
      @withdrawal ||= ::Withdrawal
                      .joins(:entry_request)
                      .find_by(entry_requests: { id: request_id })
    end

    def payout_failed!
      raise Withdrawals::PayoutError,
            "CoinsPaid: #{error_message}"
    end
  end
end
