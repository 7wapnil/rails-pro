# frozen_string_literal: true

module Payments
  class Deposit < Operation
    include Methods

    PAYMENT_METHODS = [
      *::Payments::Crypto::Deposit::PAYMENT_METHODS,
      *::Payments::Fiat::Deposit::PAYMENT_METHODS
    ].freeze

    BUSINESS_ERRORS = [
      ::Deposits::DepositLimitRestrictionError,
      ::Deposits::DepositAttemptError,
      ::Deposits::CurrencyRuleError,
      ::CustomerBonuses::ActivationError
    ].freeze

    private

    def execute_operation
      deposit_handler.call(transaction)
    end

    def deposit_handler
      case transaction.currency
      when :fiat?.to_proc
        ::Payments::Fiat::Deposit
      when :crypto?.to_proc
        ::Payments::Crypto::Deposit
      else
        non_supported_currency!
      end
    end

    def non_supported_currency!
      raise ::Payments::NotSupportedError, 'Non supported currency kind'
    end
  end
end
