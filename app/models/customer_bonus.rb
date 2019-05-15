# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  acts_as_paranoid

  default_scope { order(:created_at) }

  # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION
  enum status: {
    initial: INITIAL = 'initial',
    active: ACTIVE = 'active',
    expired: EXPIRED = 'expired',
    failed: FAILED = 'failed',
    cancelled: CANCELLED = 'cancelled',
    completed: COMPLETED = 'completed'
  }

  enum kind: Bonus.kinds
  enum expiration_reason: {
    manual_cancel: MANUAL_CANCEL = 'manual_cancel',
    expired_by_date: EXPIRED_BY_DATE = 'expired_by_date',
    converted: CONVERTED = 'converted',
    withdrawal: WITHDRAWAL = 'withdrawal'
  }

  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: Bonus.name
  belongs_to :entry, optional: true
  has_many :bets
  has_one :deposit_request

  attr_reader :amount
  attr_writer :status # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION

  def ended_at
    created_at + valid_for_days.days
  end

  def expired?
    deleted_at || ended_at < Time.zone.now
  end

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    with_deleted.where(customer: customer)
  end

  # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION
  def status
    expired? ? 'expired' : 'active'
  end
end
