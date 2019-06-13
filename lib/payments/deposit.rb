# Part of code copied from old Mihail's solution and looks like not the best
# one.
# On execution entry request (initial or failed) are not saved, but must be!
# So, I propose to update this code with following order:
#
# - Create initial request (status initial)
# - Validate transaction
# -- If invalid or error raised update request to FAILED with result message
# - return payment page url
#
#
# Validation of business rules (deposit amount limit, attempts) moved to
# Transaction
#
module Payments
  class Deposit < Operation
    include Methods

    PAYMENT_METHODS = [
      ::Payments::Methods::CREDIT_CARD,
      ::Payments::Methods::NETELLER,
      ::Payments::Methods::SKRILL,
      ::Payments::Methods::PAYSAFECARD,
      ::Payments::Methods::BITCOIN
    ].freeze

    BUSINESS_ERRORS = [
      ::Deposits::DepositLimitRestrictionError,
      ::Deposits::DepositAttemptError,
      ::Deposits::CurrencyRuleError,
      ::CustomerBonuses::ActivationError
    ].freeze

    INPUT_ERRORS = [
      ::SafeCharge::InvalidInputError
    ].freeze

    private

    attr_reader :entry_request, :customer_bonus

    def execute_operation
      apply_bonus_code!
      create_entry_request
      assign_request_to_transaction

      return entry_request_failed! if entry_request.failed?

      provider.payment_page_url(transaction)
    rescue *INPUT_ERRORS => error
      raise ::Payments::GatewayError, error.message
    end

    def apply_bonus_code!
      return unless transaction.bonus

      @customer_bonus = ::CustomerBonuses::Create.call(
        wallet: transaction.wallet,
        bonus: transaction.bonus,
        amount: transaction.amount
      )
    rescue *BUSINESS_ERRORS => error
      raise ::Payments::BusinessRuleError, error.message
    end

    def create_entry_request
      @entry_request = EntryRequests::Factories::Deposit.call(
        wallet: transaction.wallet,
        amount: transaction.amount,
        mode: transaction.method,
        customer_bonus: customer_bonus
      )
    end

    def assign_request_to_transaction
      transaction.id = entry_request.id
    end

    def entry_request_failed!
      raise Payments::BusinessRuleError, entry_request.result['message']
    end

    def provider
      find_method_provider(transaction.method).new
    end
  end
end
