class Bet < ApplicationRecord
  include StateMachines::BetStateMachine

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin

  scope :expired_live, -> do
    condition = 'bets.validation_ticket_sent_at <= :seconds_ago
                         AND bets.status = :status
                         AND events.traded_live = true'
    status_code = Bet.statuses[:sent_to_external_validation]
    joins(odd: { market: [:event] }).where(condition,
                                           seconds_ago: 10.seconds.ago,
                                           status: status_code)
  end

  scope :expired_prematch, -> do
    condition = 'bets.validation_ticket_sent_at <= :seconds_ago
                         AND bets.status = :status
                         AND events.traded_live = false'
    status_code = Bet.statuses[:sent_to_external_validation]
    joins(odd: { market: [:event] }).where(condition,
                                           seconds_ago: 3.seconds.ago,
                                           status: status_code)
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
end
