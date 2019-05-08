# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  acts_as_paranoid

  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: 'Bonus', optional: true
  belongs_to :entry, optional: true
  has_many :bets

  enum kind: Bonus.kinds
  enum expiration_reason: {
    manual_cancel: MANUAL_CANCEL = 'manual_cancel',
    expired_by_date: EXPIRED_BY_DATE = 'expired_by_date',
    converted: CONVERTED = 'converted',
    withdrawal: WITHDRAWAL = 'withdrawal'
  }

  attr_reader :amount

  def ended_at
    created_at + valid_for_days.days
  end

  def expired?
    deleted_at || ended_at < Time.zone.now
  end

  def applied?
    !expired? && rollover_balance.present?
  end

  def status
    expired? ? 'expired' : 'active'
  end

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    with_deleted.where(customer: customer)
  end

  def activated?
    entry_id.present?
  end
end
