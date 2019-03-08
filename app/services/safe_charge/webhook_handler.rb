module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      response.validate!
      update_entry_request_mode!

      entry_request.update_attribute(:external_id, response.transaction_id)
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
  end
end
