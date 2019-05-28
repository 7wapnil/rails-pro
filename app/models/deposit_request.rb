# frozen_string_literal: true

class DepositRequest < CustomerTransaction
  BUSINESS_ERRORS = [
    Deposits::DepositLimitRestrictionError,
    Deposits::DepositAttemptError,
    CustomerBonuses::ActivationError
  ].freeze
end
