class EntryRequest < ApplicationRecord
  include EntryKinds

  belongs_to :customer
  belongs_to :currency
  belongs_to :initiator, polymorphic: true
  belongs_to :origin, polymorphic: true, optional: true

  default_scope { order(created_at: :desc) }

  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2
  }

  enum mode: {
    cashier: 0,
    sports_ticket: 1
  }

  validates :amount,
            :kind,
            presence: true

  validates :comment, presence: true, unless: :customer_initiated?
  validates :amount, numericality: true
  validates :status, inclusion: { in: statuses.keys }
  validates :mode, inclusion: { in: modes.keys }
  validates :kind, inclusion: { in: kinds.keys }

  delegate :code, to: :currency, prefix: true

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
    new_value = -new_value if CREDIT_KINDS.key?(kind.to_sym)

    self.amount = new_value
  end
end
