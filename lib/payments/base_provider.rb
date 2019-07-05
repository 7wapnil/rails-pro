# frozen_string_literal: true

module Payments
  class BaseProvider
    def payment_page_url(_transaction)
      raise ::NotImplementedError
    end

    def handle_response(request)
      response_handler.call(request)
    end

    def response_handler
      raise ::NotImplementedError
    end

    def process_payout
      raise ::NotImplementedError
    end
  end
end
