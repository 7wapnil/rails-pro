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

    def process_withdrawal(transaction)
      withdrawal_handler.call(transaction: transaction)
    end

    def withdrawal_handler
      raise ::NotImplementedError, 'Implement #withdrawal_handler'
    end
  end
end
