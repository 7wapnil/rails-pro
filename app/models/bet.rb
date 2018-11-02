class Bet < ApplicationRecord # rubocop:disable Metrics/ClassLength
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

  class << self
    def with_country
      sub_query = <<~SQL
        SELECT  event_scopes.name FROM event_scopes
         INNER JOIN scoped_events ON event_scopes.id = scoped_events.event_scope_id
         INNER JOIN events ON scoped_events.event_id = events.id
         INNER JOIN markets ON events.id = markets.event_id
         INNER JOIN odds ON markets.id = odds.market_id
         WHERE odds.id = bets.odd_id AND event_scopes.kind = #{EventScope.kinds[:country]} LIMIT 1
      SQL
      sql = "bets.*, (#{sub_query}) AS country"
      select(sql)
    end

    def with_tournament
      sub_query = <<~SQL
        SELECT  event_scopes.name FROM event_scopes
         INNER JOIN scoped_events ON event_scopes.id = scoped_events.event_scope_id
         INNER JOIN events ON scoped_events.event_id = events.id
         INNER JOIN markets ON events.id = markets.event_id
         INNER JOIN odds ON markets.id = odds.market_id
         WHERE odds.id = bets.odd_id AND event_scopes.kind = #{EventScope.kinds[:tournament]} LIMIT 1
      SQL
      sql = "bets.*, (#{sub_query}) AS tournament"
      select(sql)
    end

    def with_sport
      sub_query = <<~SQL
        SELECT  titles.name FROM titles
         INNER JOIN events ON events.title_id = titles.id
         INNER JOIN markets ON markets.event_id = events.id
         INNER JOIN odds ON markets.id = odds.market_id
         WHERE odds.id = bets.odd_id LIMIT 1
      SQL
      sql = "bets.*, (#{sub_query}) AS sport"
      select(sql)
    end

    def with_winnings
      select('bets.*, (bets.amount * bets.odd_value) AS winning')
    end

    def ransackable_scopes(_auth_object = nil)
      %w[with_winnings]
    end

    def ransortable_attributes(auth_object = nil)
      super(auth_object) + %i[sort_by_winning_asc sort_by_winning_desc]
    end

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

  def display_status
    if PENDING_STATUSES_MASK.include? status
      'pending'
    else
      status
    end
  end

  def win_amount
    return nil unless settlement_status
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
end
