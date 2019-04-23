# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  enum kind: Bonus.kinds
  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: 'Bonus', optional: true
  belongs_to :entry, optional: true
  has_many :bets

  attr_reader :amount

  enum expiration_reason: {
    manual_cancel: MANUAL_CANCEL = 'manual_cancel',
    expired_by_new_activation:
      EXPIRED_BY_NEW_ACTIVATION = 'expired_by_new_activation',
    expired_by_date: EXPIRED_BY_DATE = 'expired_by_date',
    converted: CONVERTED = 'converted'
  }

  acts_as_paranoid

  def close!(deactivation_service, options = {})
    deactivation_service.call(self, options)
  end

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

  def add_funds(_amount)
    # TODO: Implementation needed
  end

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    with_deleted
      .where(customer: customer)
  end

  def activated?
    entry_id.present?
  end
end
