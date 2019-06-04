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
      ::CustomerBonuses::ActivationError
    ].freeze

    protected

    def execute_operation
      entry_request = initial_entry_request
      @transaction.id = entry_request.id
      apply_bonus_code!

      provider.payment_page_url(@transaction)
    end

    private

    def provider
      find_method_provider(@transaction.method).new
    end

    def create_entry_request
      apply_bonus_code!
      initial_entry_request
    end

    def apply_bonus_code!
      return unless transaction.bonus

      ::CustomerBonuses::Create.call(
        wallet: transaction.wallet,
        original_bonus: transaction.bonus,
        amount: transaction.amount
      )
    end

    def initial_entry_request
      request = EntryRequests::Factories::Deposit.call(
        wallet: transaction.wallet,
        amount: transaction.amount,
        mode: transaction.method
      )
      request.save!

      request
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
