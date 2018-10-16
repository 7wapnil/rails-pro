class Bet < ApplicationRecord
  include StateMachines::BetStateMachine
  ENTRY_REQUEST_WIN_KIND = EntryRequest.kinds[:win]

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

  def actual_payout
    Entry.select(:amount)
         .joins(:wallet)
         .where(origin: self, kind: ENTRY_REQUEST_WIN_KIND)
         .map(&:amount)
         .inject(0) { |sum, x| sum + x }
  end
end
