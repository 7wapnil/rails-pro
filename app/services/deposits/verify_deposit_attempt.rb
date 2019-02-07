module Deposits
  class VerifyDepositAttempt < ApplicationService
    MAX_DEPOSIT_ATTEMPTS = ENV.fetch('MAX_DEPOSIT_ATTEMPTS', 5).to_i
    def initialize(customer)
      @customer = customer
    end

    def call
      verify_max_deposit_attempts!
    end

    private

    attr_reader :customer

    def verify_max_deposit_attempts!
      attempts_exceeded_error if customer.deposit_attempts > MAX_DEPOSIT_ATTEMPTS # rubocop:disable Metrics/LineLength
    end

    def attempts_exceeded_error
      msg = I18n.t('errors.messages.deposit_attempts_exceeded')
      raise DepositAttemptError, msg
    end
  end
end
