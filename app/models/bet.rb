class Bet < ApplicationRecord
  include AASM

  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2,
    settled: 3,
    cancelled: 4
  }

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :succeeded
    state :failed
    state :settled
    state :cancelled

    event :failure do
      transitions from: :pending,
                  to: :failed,
                  after: proc { |msg| update(message: msg) }
    end

    event :settle do
      transitions from: :succeeded,
                  to: :settled,
                  after: proc { |args| update_attributes(args) }
    end
  end

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin

  validates :odd_value,
            numericality: {
              equal_to: ->(bet) { bet.odd.value },
              on: :create
            }
  validates :result, inclusion: { in: [true, false] }
  validates :void_factor,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 1
            },
            allow_nil: true

  delegate :market, to: :odd

  def win_amount
    return nil if result.nil?
    return 0 unless result
    (amount - refund_amount) * odd_value
  end

  def refund_amount
    return nil if result.nil?
    return 0 if void_factor.nil?
    amount * void_factor
  end
end
