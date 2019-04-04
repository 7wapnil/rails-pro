# frozen_string_literal: true

class WithdrawalRequest < ApplicationRecord
  has_one :entry_request, as: :origin
  belongs_to :actioned_by, class_name: 'User', optional: true

  enum status: {
    pending: PENDING = 'pending',
    approved: APPROVED = 'approved',
    rejected: REJECTED = 'rejected'
  }

  def loggable_attributes
    { id: id, status: status }
  end
end
