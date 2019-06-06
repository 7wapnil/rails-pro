# frozen_string_literal: true

module Payments
  class GatewayError < ::StandardError; end

  class NotSupportedError < GatewayError; end

  class TechnicalError < GatewayError
    def message
      I18n.t('errors.messages.technical_error_happened')
    end
  end

  class FailedError < GatewayError
    def message
      I18n.t('errors.messages.payment_failed_error')
    end
  end

  class CancelledError < GatewayError
    def message
      I18n.t('errors.messages.payment_cancelled_error')
    end
  end

  class BusinessRuleError < ::StandardError; end

  class InvalidTransactionError < ::StandardError
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
