module Deposits
  class InitiateHostedDepositService < ApplicationService
    def initialize(customer:, currency:, amount:, bonus_code: nil)
      @customer = customer
      @currency = currency
      @amount = amount
      @bonus_code = bonus_code
    end

    def call
      validate_business_rules!

      initial_entry_request
    rescue Deposits::InvalidDepositRequestError => e
      Rails.logger.info e.message
      missing_data_entry_request(e)
    end

    private

    def validate_business_rules!
      # TODO: Existing deposit request found
      # TODO: Check bonus code
      # TODO: Responsible gambling manager check
      # TODO: Rates check

      true
    end

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

    def missing_data_entry_request(error)
      EntryRequest.new(
        status: EntryRequest::FAILED,
        amount: @amount,
        initiator: @customer,
        customer: @customer,
        currency: @currency,
        result: { message: error.message },
        mode: EntryRequest::SYSTEM,
        kind: EntryRequest::DEPOSIT
      )
    end
  end
end
