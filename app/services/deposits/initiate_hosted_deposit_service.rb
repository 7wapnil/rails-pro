module Deposits
  class InitiateHostedDepositService < ApplicationService
    def initialize(customer:, currency:, amount:, bonus_code: nil)
      @customer = customer
      @currency = currency
      @amount = amount
      @bonus_code = bonus_code
    end

    def call
      # TODO: Check bonus code
      # TODO: Responsible gambling manager check
      # TODO: Rates check
      initial_entry_request
    end

    private

    def initial_entry_request
      EntryRequest.new(
        status: EntryRequest::INITIAL,
        amount: @amount,
        initiator: @customer,
        customer: @customer,
        currency: @currency,
        mode: EntryRequest::SYSTEM,
        kind: EntryRequest::DEPOSIT
      )
    end
  end
end
