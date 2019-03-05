# frozen_string_literal: true

module EntryRequests
  class PaymentMethodService < ApplicationService
    PAYMENT_METHOD_MAP = {
      cc_card: EntryRequest::VISA_MASTERCARD
    }.freeze

    def initialize(payment_method_code:, entry_request:)
      @payment_method_code = payment_method_code
      @entry_request       = entry_request
    end

    def call
      unsupported_payment_method if mode_from_code.nil?

      entry_request.update(mode: mode_from_code)
    end

    private

    attr_reader :entry_request, :payment_method_code

    def mode_from_code
      PAYMENT_METHOD_MAP[payment_method_code.to_sym]
    end

    def fail_message
      "Payment method '#{payment_method_code}' is not implemented"
    end

    def unsupported_payment_method
      entry_request.register_failure!(fail_message)

      raise(NotImplementedError, fail_message)
    end
  end
end
