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
    attr_reader :humanized
    alias_method :humanized?, :humanized

    def initialize(msg = nil)
      super(msg || default_message)
      @humanized = msg.present?
    end

    def default_message
      I18n.t('errors.messages.payment_failed_error')
    end
  end

  class CancelledError < GatewayError
    def message
      I18n.t('errors.messages.payment_cancelled_error')
    end
  end

  class BusinessRuleError < ::StandardError
    NO_ATTRIBUTE = 'base'

    attr_reader :attribute

    def initialize(message, attribute = nil)
      super(message)
      assign_attribute(attribute)
    end

    private

    def assign_attribute(attribute)
      @attribute = attribute unless attribute.to_s == NO_ATTRIBUTE
    end
  end

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
