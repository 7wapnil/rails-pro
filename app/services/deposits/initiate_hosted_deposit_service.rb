module Deposits
  class InitiateHostedDepositService < ApplicationService
    BUSINESS_ERRORS = [
      Deposits::DepositLimitRestrictionError,
      Deposits::InvalidDepositRequestError
    ].freeze

    AMOUNT_TYPE_ERROR = ArgumentError.new('amount must be Numeric')

    def initialize(customer:, currency:, amount:, bonus_code: nil)
      @customer = customer
      @currency = currency
      @amount = amount
      @bonus_code = bonus_code
    end

    def call
      validate_ambiguous_input!
      validate_business_rules!
      apply_bonus_code!

      initial_entry_request
    rescue *BUSINESS_ERRORS => e
      Rails.logger.info e.message
      entry_request_failure(e)
    end

    private

    def apply_bonus_code!
      return unless bonus

      Bonuses::ActivationService.call(wallet, bonus, @amount)
    end

    def wallet
      Wallet.find_or_create_by!(customer: @customer, currency: @currency)
    end

    def bonus
      @bonus ||= Bonus.find_by_code(@bonus_code)
    end

    def validate_ambiguous_input!
      raise AMOUNT_TYPE_ERROR unless @amount.is_a? Numeric
    end

    def validate_business_rules!
      # TODO: Existing deposit request found
      # TODO: Check bonus code
      DepositLimitCheckService
        .call(@customer, @amount, @currency)
      VerifyDepositAttempt.call(@customer)

      true
    end

    def initial_entry_request
      EntryRequests::Factories::Deposit.call(
        wallet: wallet,
        amount: @amount,
        mode: EntryRequest::SAFECHARGE_UNKNOWN
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
        mode: EntryRequest::SAFECHARGE_UNKNOWN,
        kind: EntryRequest::DEPOSIT
      )
    end
  end
end
