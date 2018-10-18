class Bet < ApplicationRecord
  include StateMachines::BetStateMachine

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin

  class << self
    def expired_live
      timeout = ENV.fetch('MTS_LIVE_VALIDATION_TIMEOUT') { 10 }.to_i
      condition = 'bets.validation_ticket_sent_at <= :expired_at
                         AND events.traded_live = true'
      sent_to_external_validation
        .joins(odd: { market: [:event] })
        .where(condition,
               expired_at: timeout.seconds.ago)
    end

    def expired_prematch
      timeout = ENV.fetch('MTS_PREMATCH_VALIDATION_TIMEOUT') { 3 }.to_i
      condition = 'bets.validation_ticket_sent_at <= :expired_at
                         AND events.traded_live = false'
      sent_to_external_validation
        .joins(odd: { market: [:event] })
        .where(condition,
               expired_at: timeout.seconds.ago)
    end
  end

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
    BalanceEntry
      .joins(:entry)
      .where(entries: { origin: self, kind: Entry.kinds[:win] })
      .sum(:amount)
  end
end
