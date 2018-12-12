class ActivatedBonus < ApplicationRecord
  enum kind: Bonus.kinds
  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: 'Bonus', optional: true

  attr_reader :amount

  acts_as_paranoid

  def deactivate!
    destroy!
  end

  def ended_at
    created_at + valid_for_days.days
  end

  def expired?
    deleted_at || ended_at < Time.zone.now
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
end
