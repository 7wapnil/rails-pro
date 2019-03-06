# frozen_string_literal: true

class EntryRequest < ApplicationRecord
  include EntryKinds
  include Loggable

  belongs_to :customer
  belongs_to :currency
  belongs_to :initiator, polymorphic: true
  belongs_to :origin, polymorphic: true, optional: true
  has_many :balance_entry_requests

  has_one :bonus_balance_entry_request, -> { bonus },
          class_name: BalanceEntryRequest.name

  default_scope { order(created_at: :desc) }

  enum status: {
    initial:   INITIAL = 'initial',
    pending:   PENDING = 'pending',
    succeeded: SUCCEEDED = 'succeeded',
    failed:    FAILED = 'failed'
  }

  enum mode: {
    cashier: CASHIER = 'cashier',
    system: SYSTEM = 'system',
    simulated: SIMULATED = 'simulated',
    credit_card: CREDIT_CARD = 'credit_card'
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

  before_validation :adjust_amount_value

  def customer_initiated?
    self[:initiator_type] == Customer.to_s
  end

  def result_message
    return unless self[:result]

    @message = self[:result]['message']
  end

  def loggable_attributes
    { id: id,
      kind: kind,
      amount: amount,
      comment: comment,
      mode: mode }
  end

  def register_failure!(message)
    update_columns(
      status: EntryRequest::FAILED,
      result: { message: message }
    )
    false
  end

  private

  def adjust_amount_value
    return unless amount && kind

    new_value = amount.abs
    new_value = -new_value if CREDIT_KINDS.key?(kind.to_sym)

    self.amount = new_value
  end
end
