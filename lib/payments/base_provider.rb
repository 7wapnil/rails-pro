module Payments
  class BaseProvider
    def payment_page_url(_transaction)
      raise ::NotImplementedError
    end

    def handle_payment_response(params)
      handler = payment_response_handler.new(params)
      handler.call
    end

    def payment_response_handler
      raise ::NotImplementedError
    end
  end
end
