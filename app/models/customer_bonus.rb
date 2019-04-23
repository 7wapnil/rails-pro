# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  enum kind: Bonus.kinds
  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: 'Bonus', optional: true
  belongs_to :entry, optional: true

  attr_reader :amount

  enum expiration_reason: {
    manual_cancel: MANUAL_CANCEL = 'manual_cancel',
    expired_by_date: EXPIRED_BY_DATE = 'expired_by_date',
    converted: CONVERTED = 'converted'
  }

  validate :customer_has_no_active_bonus, on: :create

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

  private

  def customer_has_no_active_bonus
    valid = customer.active_bonus.present? || customer.active_bonus.new_record?
    message_key = 'errors.messages.customer_has_active_bonus'
    errors.add(:customer, I18n.t(message_key)) unless valid
  end
end
