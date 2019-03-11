module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      response.validate!
      update_entry_request_mode!

      return if response.pending?
      return entry_request.succeeded! if response.approved?

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
