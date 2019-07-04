# frozen_string_literal: true

module Payments
  class BaseProvider
    def payment_page_url(_transaction)
      raise ::NotImplementedError
    end

    def handle_deposit_response(params)
      deposit_response_handler.call(params)
    end

    def deposit_response_handler
      raise ::NotImplementedError
    end
  end
end
