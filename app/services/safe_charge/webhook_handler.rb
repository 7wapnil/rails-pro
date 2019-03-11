module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      save_external_id
      response.validate!
      update_entry_request_mode!

      return entry_request.succeeded! if response.approved?
      return entry_request.pending! if response.pending?

      entry_request.failed!
    end

    private

    attr_reader :params

    delegate :entry_request, to: :response

    def response
      @response ||= SafeCharge::DepositResponse.new(params)
    end

    def update_entry_request_mode!
      ::EntryRequests::PaymentMethodService.call(
        payment_method_code: params['payment_method'],
        entry_request:       entry_request
      )
    end

    def save_external_id
      entry_request.update!(external_id: response.transaction_id)
    end
  end
end
