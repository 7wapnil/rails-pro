module Deposits
  class InitiateHostedDepositService < ApplicationService
    def initialize(customer:, currency_code:, amount:, bonus_code: nil)
      @customer = customer
      @currency_code = currency_code
      @amount = amount
      @bonus_code = bonus_code
    end

    def call
      raise NotImplementedError
      # TODO: Check bonus code
      # TODO: Responsbile gambling manager check
      # TODO: Rates check
    end
  end
end
