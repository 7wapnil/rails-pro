module SafeCharge
  class TransactionResponseHandler < ApplicationService
    attr_reader :params, :context

    def initialize(params, context = nil)
      @params = params
      @context = context
    end

    def call
      response.validate!
      save_transaction_id
      update_entry_request_mode!
    end

    protected

    delegate :entry_request, to: :response, allow_nil: true

    def succeed_entry_request!
      # TODO: Verify balances updated accordingly
      entry_request.succeeded!
    end

    def response
      @response ||= SafeCharge::DepositResponse.new(params)
    end

    private

    def save_transaction_id
      entry_request.update!(external_id: response.transaction_id)
    end

    def update_entry_request_mode!
      ::EntryRequests::PaymentMethodService.call(
        payment_method_code: response.payment_method,
        entry_request:       entry_request
      )
    end
  end
end
