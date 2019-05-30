module Payments
  class BaseProvider
    def payment_page_url(_transaction)
      raise ::NotImplementedError
    end

    def handle_payment_response(params)
      payment_response_handler.call(params)
    end

    def payment_response_handler
      raise ::NotImplementedError
    end
  end
end
