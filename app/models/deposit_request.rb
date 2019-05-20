# frozen_string_literal: true

class DepositRequest < ApplicationRecord
  BUSINESS_ERRORS = [
    Deposits::DepositLimitRestrictionError,
    Deposits::DepositAttemptError,
    CustomerBonuses::ActivationError
  ].freeze

  belongs_to :customer_bonus, optional: true

  has_one :entry_request, as: :origin
  has_one :entry, as: :origin
end
