module Payments
  class GatewayError < ::StandardError; end

  class NotSupportedError < GatewayError; end

  class InvalidTransactionError < GatewayError
    def initialize(transaction)
      @transaction = transaction
      super
    end

    def message
      'Transaction data is invalid'
    end

    def validation_errors
      @transaction.errors
    end
  end
end
