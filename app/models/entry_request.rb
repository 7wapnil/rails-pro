class EntryRequest < ApplicationRecord
  include EntryKinds

  belongs_to :customer
  belongs_to :currency
  belongs_to :initiator, polymorphic: true

  default_scope { order(created_at: :desc) }

  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2
  }

  enum origin: {
    cashier: 0
  }

  validates :amount,
            :kind,
            presence: true

  validates :comment, presence: true, unless: :customer_initiated?
  validates :amount, numericality: true
  validates :status, inclusion: { in: statuses.keys }
  validates :origin, inclusion: { in: origins.keys }
  validates :kind, inclusion: { in: kinds.keys }

  before_validation { adjust_amount_value }

  def customer_initiated?
    self[:initiator_type] == Customer.to_s
  end

  def result_message
    return unless self[:result]

    @message = self[:result]['message']
  end

  private

  def adjust_amount_value
    return unless amount && kind

    new_value = amount.abs
    new_value = -new_value if CREDIT_KINDS.keys.include?(kind.to_sym)

    self.amount = new_value
  end
end
