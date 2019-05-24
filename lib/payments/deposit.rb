module Payments
  class Deposit < Operation
    include Methods

    BUSINESS_ERRORS = [
      ::Deposits::DepositLimitRestrictionError,
      ::Deposits::InvalidDepositRequestError
    ].freeze

    protected

    def execute_operation
      entry_request = create_entry_request
      @transaction.id = entry_request.id

      provider.payment_page_url(@transaction)
    end

    private

    def provider
      find_method_provider(@transaction.method).new
    end

    def create_entry_request
      validate_business_rules!
      apply_bonus_code!

      initial_entry_request
    rescue *BUSINESS_ERRORS => e
      Rails.logger.info e.message
      entry_request_failure(e)
    end

    def validate_business_rules!
      # TODO: Existing deposit request found
      # TODO: Check bonus code
      ::Deposits::DepositLimitCheckService.call(transaction.customer,
                                                transaction.amount,
                                                transaction.currency)
      ::Deposits::VerifyDepositAttempt.call(transaction.customer)
    end

    def apply_bonus_code!
      return unless transaction.bonus

      ::CustomerBonuses::Create.call(
        wallet: transaction.wallet,
        original_bonus: transaction.bonus,
        amount: transaction.amount
      )
    end

    def wallet
      Wallet.find_or_create_by!(customer: @customer, currency: @currency)
    end

    def bonus
      @bonus ||= Bonus.find_by_code(@bonus_code)
    end

    def initial_entry_request
      EntryRequests::Factories::Deposit.call(
        wallet: transaction.wallet,
        amount: transaction.amount,
        mode: transaction.method
      )
    end

    def entry_request_failure(error)
      EntryRequest.new(
        status: EntryRequest::FAILED,
        amount: transaction.amount,
        initiator: transaction.customer,
        customer: transaction.amount.customer,
        currency: transaction.amount.currency,
        result: { message: error.message },
        mode: transaction.method,
        kind: EntryRequest::DEPOSIT
      )
    end
  end
end
