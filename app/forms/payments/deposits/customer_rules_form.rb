# frozen_string_literal: true

module Payments
  module Deposits
    class CustomerRulesForm
      include ActiveModel::Model

      attr_accessor :customer, :amount, :wallet

      validates :customer, presence: true

      validate :validate_deposit_limit
      validate :validate_attempts

      def validate_deposit_limit
        return if deposit_limit

        deposit_limit_restricted!
      end

      def validate_attempts
        return if ::Deposits::VerifyDepositAttempt.call(customer)

        attempts_exceeded!
      end

      def deposit_limit
        ::Deposits::DepositLimitCheckService.call(customer, amount, currency)
      end

      def currency
        @currency ||= wallet&.currency
      end

      def deposit_limit_restricted!
        errors.add(
          :limit,
          I18n.t('errors.messages.deposit_limit_exceeded')
        )
      end

      def attempts_exceeded!
        errors.add(
          :attempts,
          I18n.t('errors.messages.deposit_attempts_exceeded')
        )
      end
    end
  end
end
