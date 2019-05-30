module Payments
  class GatewayError < ::StandardError; end

  class NotSupportedError < GatewayError; end

  class TechnicalError < GatewayError
    def message
      I18n.t('errors.messages.technical_error_happened')
    end
  end

  class CanceledError < GatewayError
    def message
      I18n.t('errors.messages.deposit_request_cancelled')
    end
  end

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
