# frozen_string_literal: true

class CustomerTransaction < ApplicationRecord
  STATUSES = {
    pending: PENDING = 'pending',
    processing: PROCESSING = 'processing',
    succeeded: SUCCEEDED = 'succeeded',
    rejected: REJECTED = 'rejected',
    failed: FAILED = 'failed'
  }.freeze

  TYPES = %w[Deposit Withdrawal].freeze

  has_many :entry_requests, as: :origin

  has_one :entry_request,
          -> { unscoped.order(:created_at) },
          as: :origin

  has_one :entry,
          -> { unscoped.order(:created_at) },
          through: :entry_request,
          required: false,
          as: :origin

  belongs_to :actioned_by, class_name: User.name, optional: true

  belongs_to :customer_bonus, optional: true

  enum status: STATUSES

  delegate :customer, to: :entry_request
end
