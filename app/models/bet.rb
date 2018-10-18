class Bet < ApplicationRecord
  include StateMachines::BetStateMachine

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

  scope :with_settlement_and_winnings, -> do
    joins(:odd)
      .select('bets.*, (bets.amount * bets.odd_value) AS winning,
      odds.won as settlement')
  end

  scope :sort_by_winning_asc, -> do
    joins(:odd)
      .select('bets.*, (bets.amount * bets.odd_value) as winning,
      odds.won as settlement')
      .order('winning')
  end

  scope :sort_by_winning_desc, -> do
    joins(:odd)
      .select('bets.*, (bets.amount * bets.odd_value) as winning,
      odds.won as settlement')
      .order('winning DESC')
  end

  scope :sort_by_settlement_asc, -> do
    joins(:odd)
      .select('bets.*, (bets.amount * bets.odd_value) as winning,
      odds.won as settlement')
      .order('settlement')
  end

  scope :sort_by_settlement_desc, -> do
    joins(:odd)
      .select('bets.*, (bets.amount * bets.odd_value) as winning,
      odds.won as settlement')
      .order('settlement DESC')
  end

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

  class << self
    def ransackable_scopes(_auth_object = nil)
      %w[with_settlement_and_winnings]
    end

    def ransortable_attributes(auth_object = nil)
      super(auth_object) + %i[
        sort_by_winning_asc
        sort_by_winning_desc
        sort_by_settlement_asc
        sort_by_settlement_desc
      ]
    end
  end
end
