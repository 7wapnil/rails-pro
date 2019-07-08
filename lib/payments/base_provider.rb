# frozen_string_literal: true

module Payments
  class BaseProvider
    def payment_page_url(_transaction)
      raise ::NotImplementedError
    end

    def handle_callback(request)
      callback_handler.call(request)
    end

    def handle_deposit_response(params)
      deposit_response_handler.call(params)
    end

    def process_payout(transaction)
      payout_request_handler.call(transaction)
    end

    def callback_handler
      raise ::NotImplementedError
    end

    def deposit_response_handler
      raise ::NotImplementedError
    end

    def payout_request_handler
      raise NotImplementedError
    end
  end
end
