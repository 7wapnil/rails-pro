# frozen_string_literal: true

module Payments
  class Validation < Operation
    include Methods

    private

    def execute_operation
      customer_validation_handler.call(transaction)
    end

    def customer_validation_handler
      case transaction.currency
      when :fiat?.to_proc
        ::Payments::Fiat::Validation
      when :crypto?.to_proc
        ::Payments::Crypto::Validation
      else
        non_supported_currency!
      end
    end

    def non_supported_currency!
      raise ::Payments::NotSupportedError, 'Non supported currency kind'
    end
  end
end
