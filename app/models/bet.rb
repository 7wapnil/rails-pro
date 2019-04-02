# frozen_string_literal: true

class Bet < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include StateMachines::BetStateMachine

  PENDING_STATUSES_MASK = [
    ACCEPTED,
    SENT_TO_EXTERNAL_VALIDATION,
    SENT_TO_INTERNAL_VALIDATION,
    VALIDATED_INTERNALLY
  ].freeze

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency
  belongs_to :customer_bonus, optional: true

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin
  has_one :market, through: :odd
  has_one :event, through: :market
  has_one :title, through: :event

  has_one :winning, -> { win }, class_name: Entry.name, as: :origin

  has_many :entry_requests, as: :origin
  has_many :entries, as: :origin
  has_many :tournaments,
           -> { where(kind: EventScope::TOURNAMENT) },
           through: :event,
           source: :event_scopes,
           class_name: EventScope.name
  has_many :categories,
           -> { where(kind: EventScope::CATEGORY) },
           through: :event,
           source: :event_scopes,
           class_name: EventScope.name

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

  scope :pending, -> { where(status: Bet::PENDING_STATUSES_MASK) }
  scope :sort_by_winning_amount_asc,
        -> { with_winning_amount.order('winning_amount') }
  scope :sort_by_winning_amount_desc,
        -> { with_winning_amount.order('winning_amount DESC') }

  class << self
    def from_regular_customers
      left_outer_joins(:customer).where(
        customers: { account_kind: Customer::REGULAR }
      )
    end

    def with_category
      sub_query = <<~SQL
        SELECT  event_scopes.name FROM event_scopes
         INNER JOIN scoped_events ON event_scopes.id = scoped_events.event_scope_id
         INNER JOIN events ON scoped_events.event_id = events.id
         INNER JOIN markets ON events.id = markets.event_id
         INNER JOIN odds ON markets.id = odds.market_id
         WHERE odds.id = bets.odd_id AND event_scopes.kind = '#{EventScope::CATEGORY}' LIMIT 1
      SQL
      sql = "bets.*, (#{sub_query}) AS category"
      select(sql)
    end

    def with_tournament
      sub_query = <<~SQL
        SELECT  event_scopes.name FROM event_scopes
         INNER JOIN scoped_events ON event_scopes.id = scoped_events.event_scope_id
         INNER JOIN events ON scoped_events.event_id = events.id
         INNER JOIN markets ON events.id = markets.event_id
         INNER JOIN odds ON markets.id = odds.market_id
         WHERE odds.id = bets.odd_id AND event_scopes.kind = '#{EventScope::TOURNAMENT}' LIMIT 1
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

    def with_winning_amount
      select('bets.*, (bets.amount * bets.odd_value) AS winning_amount')
    end

    def ransackable_scopes(_auth_object = nil)
      %w[with_winning_amount]
    end

    def ransortable_attributes(auth_object = nil)
      super(auth_object) +
        %i[sort_by_winning_amount_asc sort_by_winning_amount_desc]
    end

    def expired_live
      timeout = ENV.fetch('MTS_LIVE_VALIDATION_TIMEOUT_SECONDS', 10).to_i
      condition = 'bets.validation_ticket_sent_at <= :expired_at
                         AND events.traded_live = true'
      sent_to_external_validation
        .joins(odd: { market: [:event] })
        .where(condition,
               expired_at: timeout.seconds.ago)
    end

    def expired_prematch
      timeout = ENV.fetch('MTS_PREMATCH_VALIDATION_TIMEOUT_SECONDS', 3).to_i
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

  def potential_win
    amount * odd_value
  end

  def potential_loss
    amount
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
      .where(entries: { origin: self, kind: Entry::WIN })
      .sum(:amount)
  end

  def real_money_total
    return 0.0 unless entry_request&.succeeded?

    @real_money_total ||= entry_request
                          .balance_entry_requests
                          .real_money.first.amount
  end

  def bonus_money_total
    return 0.0 unless entry_request&.succeeded?

    @bonus_money_total ||= entry_request
                           .balance_entry_requests
                           .bonus.first.amount
  end
end
