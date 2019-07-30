# frozen_string_literal: true

class EntryRequest < ApplicationRecord
  include EntryKinds
  include Loggable

  belongs_to :customer
  belongs_to :currency
  belongs_to :initiator, polymorphic: true, optional: true
  belongs_to :origin, polymorphic: true, optional: true
  belongs_to :deposit, foreign_key: :origin_id, optional: true
  belongs_to :withdrawal, foreign_key: :origin_id, optional: true

  has_many :balance_entry_requests, dependent: :destroy

  has_one :real_money_balance_entry_request, -> { real_money },
          class_name: BalanceEntryRequest.name
  has_one :bonus_balance_entry_request, -> { bonus },
          class_name: BalanceEntryRequest.name

  has_one :entry, inverse_of: :entry_request, dependent: :nullify

  default_scope { order(created_at: :desc) }

  enum status: {
    initial:   INITIAL = 'initial',
    pending:   PENDING = 'pending',
    succeeded: SUCCEEDED = 'succeeded',
    failed:    FAILED = 'failed'
  }

  enum mode: {
    cashier: CASHIER = 'cashier',
    internal: INTERNAL = 'internal',
    safecharge_unknown: SAFECHARGE_UNKNOWN = 'safecharge_unknown',
    simulated: SIMULATED = 'simulated',
    credit_card: CREDIT_CARD = 'credit_card',
    skrill: SKRILL = 'skrill',
    neteller: NETELLER = 'neteller',
    paysafecard: PAYSAFECARD = 'paysafecard',
    sofort: SOFORT = 'sofort',
    ideal: IDEAL = 'ideal',
    bitcoin: BITCOIN = 'bitcoin',
    webmoney: WEBMONEY = 'webmoney',
    yandex: YANDEX = 'yandex',
    qiwi: QIWI = 'qiwi',
    neosurf: NEOSURF = 'neosurf'
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

  def register_failure!(message, attribute = nil)
    update_columns(
      status: EntryRequest::FAILED,
      result: { message: message, attribute: attribute }.compact
    )
    false
  end

  def self.expired
    initial.where('created_at > ?', Time.zone.yesterday.midnight)
  end

  def self.transactions
    where(
      origin_type: CustomerTransaction.to_s,
      kind: [DEPOSIT, WITHDRAW, REFUND]
    )
  end

  private

  def adjust_amount_value
    return unless amount && kind
    return if CREDIT_KINDS.include?(kind) && DEBIT_KINDS.include?(kind)

    new_value = amount.abs
    new_value = -new_value if CREDIT_KINDS.include?(kind)

    self.amount = new_value
  end
end
