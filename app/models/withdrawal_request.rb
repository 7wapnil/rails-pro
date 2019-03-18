# frozen_string_literal: true

class WithdrawalRequest < ApplicationRecord
  has_one :entry_request, as: :origin

  enum status: {
    pending: PENDING = 'pending',
    approved: APPROVED = 'approved',
    rejected: REJECTED = 'rejected'
  }

  enum payment_method: SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.keys
end
