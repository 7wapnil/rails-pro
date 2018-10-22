class Bet < ApplicationRecord
  include StateMachines::BetStateMachine

  PENDING_STATUSES_MASK = %w[
    accepted
    sent_to_external_validation
    sent_to_internal_validation
    validated_internally
  ].freeze

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin
  has_one :market, through: :odd
  has_one :event, through: :market
  has_one :title, through: :event

  validates :odd_value,
            numericality: {
              equal_to: ->(bet) { bet.odd.value },
              on: :create
            }
  validates :void_factor,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 1
            },
            allow_nil: true

  delegate :market, to: :odd

  scope :sort_by_winning_asc, -> { with_winnings.order('winning') }

  scope :sort_by_winning_desc, -> { with_winnings.order('winning DESC') }

  def display_status
    if PENDING_STATUSES_MASK.include? status
      'pending'
    else
      status
    end
  end

  def win_amount
    return nil if settlement_status.nil?
    return 0 unless won?

    (amount - refund_amount) * odd_value
  end

  def refund_amount
    return nil if settlement_status.nil?
    return 0 if void_factor.nil?

    amount * void_factor
  end

  def actual_payout
    BalanceEntry
      .joins(:entry)
      .where(entries: { origin: self, kind: Entry.kinds[:win] })
      .sum(:amount)
  end

  def self.with_winnings
    select('bets.*, (bets.amount * bets.odd_value) AS winning')
  end

  class << self
    def ransackable_scopes(_auth_object = nil)
      %w[with_winnings]
    end

    def ransortable_attributes(auth_object = nil)
      super(auth_object) + %i[sort_by_winning_asc sort_by_winning_desc]
    end
  end
end
