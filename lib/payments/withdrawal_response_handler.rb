# frozen_string_literal: true

module Payments
  class WithdrawalResponseHandler < ::ApplicationService
    delegate :entry_request, to: :withdrawal
    delegate :entry, to: :withdrawal

    protected

    attr_reader :response

    def request_id
      raise NotImplementedError, 'Implement #request_id method!'
    end

    def transactions_id
      raise NotImplementedError, 'Implement #transactions_id method!'
    end

    def withdrawal
      @withdrawal ||= ::Withdrawal
                      .joins(:entry_request)
                      .find_by(entry_requests: { id: request_id })
    end

    def succeeded!
      withdrawal.succeeded!
      entry_request.update(external_id: transactions_id)
    end

    def cancelled!(message)
      withdrawal.update!(
        status: ::Withdrawal::PENDING,
        transaction_message: message
      )
    end
  end
end
