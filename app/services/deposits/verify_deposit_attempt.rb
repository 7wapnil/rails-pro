# frozen_string_literal: true

module Deposits
  class VerifyDepositAttempt < ApplicationService
    MAX_DEPOSIT_ATTEMPTS = ENV.fetch('MAX_DEPOSIT_ATTEMPTS', 5).to_i

    def initialize(customer)
      @customer = customer
    end

    def call
      return true if customer.deposit_attempts <= MAX_DEPOSIT_ATTEMPTS

      false
    end

    private

    attr_reader :customer
  end
end
