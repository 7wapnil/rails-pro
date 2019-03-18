module SafeCharge
  class TransactionResponseHandler < ApplicationService
    attr_reader :params, :context

    def initialize(params, context = nil)
      @params = params
      @context = context
    end

    def call
      response.validate!
      save_transaction_id unless entry_request.external_id
      safecharge_unknown = EntryRequest::SAFECHARGE_UNKNOWN
      update_entry_request_mode! if entry_request.mode == safecharge_unknown
    end

    protected

    delegate :entry_request, to: :response, allow_nil: true

    def succeed_entry_request!
      return if entry_request.succeeded?

      attach_wallet_to_entry_request!
      EntryRequests::DepositService.call(entry_request: entry_request)
    end

    def response
      @response ||= SafeCharge::DepositResponse.new(params)
    end

    private

    def attach_wallet_to_entry_request!
      wallet = Wallet.find_or_create_by!(
        customer: entry_request.customer,
        currency: entry_request.currency
      )
      entry_request.update(origin: wallet)
    end

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
