# frozen_string_literal: true

class Deposit < CustomerTransaction
  BUSINESS_ERRORS = [
    Deposits::DepositLimitRestrictionError,
    Deposits::DepositAttemptError,
    CustomerBonuses::ActivationError
  ].freeze
end
