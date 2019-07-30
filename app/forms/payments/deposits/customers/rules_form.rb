# frozen_string_literal: true

module Payments
  module Deposits
    module Customers
      class RulesForm
        include ActiveModel::Model

        MAX_DEPOSIT_ATTEMPTS = ENV.fetch('MAX_DEPOSIT_ATTEMPTS', 5).to_i

        attr_accessor :customer, :amount, :wallet

        validates :customer, presence: true

        validate :validate_deposit_limit
        validate :validate_attempts

        def validate_deposit_limit
          return if deposit_limit

          deposit_limit_restricted!
        end

        def validate_attempts
          return if customer.deposit_attempts <= MAX_DEPOSIT_ATTEMPTS

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
end
