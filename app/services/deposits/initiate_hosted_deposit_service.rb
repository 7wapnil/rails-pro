# frozen_string_literal: true

module Deposits
  class InitiateHostedDepositService < ApplicationService
    def initialize(customer:, currency:, amount:, bonus_code: nil)
      @customer = customer
      @currency = currency
      @amount = amount
      @bonus_code = bonus_code
    end

    def call
      validate_ambiguous_input!
      begin
        apply_bonus_code!
      rescue CustomerBonuses::ActivationError
        entry_request.failed!
        entry_request
      end

      entry_request
    end

    private

    attr_reader :customer, :currency, :amount,
                :bonus_code, :customer_bonus

    def validate_ambiguous_input!
      return true if amount.is_a?(Numeric)

      raise ArgumentError, 'amount must be Numeric'
    end

    def apply_bonus_code!
      return unless bonus

      @customer_bonus = CustomerBonuses::Create.call(
        wallet: wallet,
        bonus: bonus,
        amount: amount
      )
    end

    def wallet
      Wallets::FindOrCreate.call(customer: customer, currency: currency)
    end

    def bonus
      @bonus ||= Bonus.from_code(bonus_code)
    end

    def entry_request
      @entry_request ||= EntryRequests::Factories::Deposit.call(
        wallet: wallet,
        amount: amount,
        customer_bonus: customer_bonus,
        mode: EntryRequest::SAFECHARGE_UNKNOWN
      )
    end
  end
end
