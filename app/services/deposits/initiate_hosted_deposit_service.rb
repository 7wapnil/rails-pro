module Deposits
  class InitiateHostedDepositService < ApplicationService
    BUSINESS_ERRORS = [
      Deposits::DepositLimitRestrictionError,
      Deposits::InvalidDepositRequestError
    ].freeze

    def initialize(customer:, currency:, amount:, bonus_code: nil)
      @customer = customer
      @currency = currency
      @amount = amount
      @bonus_code = bonus_code
    end

    def call
      validate_business_rules!

      initial_entry_request
    rescue *BUSINESS_ERRORS => e
      Rails.logger.info e.message
      entry_request_failure(e)
    end

    private

    def validate_business_rules!
      # TODO: Existing deposit request found
      # TODO: Check bonus code
      DepositLimitCheckService
        .call(@customer, @amount, @currency)
      VerifyDepositAttempt.call(@customer)

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

    def entry_request_failure(error)
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
