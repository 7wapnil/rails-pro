# frozen_string_literal: true

module Payments
  class BaseProvider
    def payment_page_url(_transaction)
      raise ::NotImplementedError
    end

    def handle_response(request)
      response_handler.call(request)
    end

    def handle_deposit_response(params)
      deposit_response_handler.call(params)
    end

    def response_handler
      raise ::NotImplementedError
    end

    def deposit_response_handler
      raise ::NotImplementedError
    end

    def process_payout(transaction)
      payout_request = perform_payout_api_call(transaction)

      payout_response_handler.call(payout_request)
    end

    protected

    def perform_payout_api_call
      raise NotImplementedError
    end

    def payout_response_handler
      raise NotImplementedError
    end
  end
end
