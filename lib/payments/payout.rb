# frozen_string_literal: true

module Payments
  class Payout < Operation
    include Methods

    PAYMENT_METHODS = [
      *::Payments::Crypto::Payout::PAYMENT_METHODS,
      *::Payments::Fiat::Payout::PAYMENT_METHODS
    ].freeze

    private

    def execute_operation
      payout_handler.call(transaction)
    end

    def payout_handler
      case transaction.currency
      when :fiat?.to_proc
        ::Payments::Fiat::Payout
      when :crypto?.to_proc
        ::Payments::Crypto::Payout
      else
        non_supported_currency!
      end
    end

    def non_supported_currency!
      raise ::Payments::NotSupportedError, 'Non supported currency kind'
    end
  end
end
