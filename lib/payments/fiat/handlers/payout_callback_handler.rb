# frozen_string_literal: true

module Payments
  module Fiat
    module Handlers
      class PayoutCallbackHandler < ::ApplicationService
        delegate :entry_request, to: :withdrawal
        delegate :entry, to: :withdrawal

        def initialize(response)
          @response = response
        end

        protected

        attr_reader :response

        def request_id
          raise NotImplementedError, 'Implement #request_id method!'
        end

        def transaction_id
          raise NotImplementedError, 'Implement #transaction_id method!'
        end

        def withdrawal
          @withdrawal ||= ::Withdrawal
                          .joins(:entry_request)
                          .find_by(entry_requests: { id: request_id })
        end

        def succeeded!
          withdrawal.succeeded!
          entry_request.update!(external_id: transaction_id)
        end

        def cancelled!(message)
          withdrawal.update!(
            status: ::Withdrawal::PENDING,
            transaction_message: message
          )
        end
      end
    end
  end
end
