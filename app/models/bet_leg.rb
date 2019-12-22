# frozen_string_literal: true

class BetLeg < ApplicationRecord
  SETTLEMENT_STATUSES = {
    lost: LOST = 'lost',
    won: WON = 'won',
    voided: VOIDED = 'voided'
  }.freeze

  CANCELLED_BY_SYSTEM = 'cancelled_by_system'
  PENDING_MANUAL_SETTLEMENT = 'pending_manual_settlement'
  STATUSES = {
    cancelled_by_system: CANCELLED_BY_SYSTEM,
    pending_manual_settlement: PENDING_MANUAL_SETTLEMENT
  }.freeze

  enum settlement_status: SETTLEMENT_STATUSES
  enum status: STATUSES

  belongs_to :bet
  belongs_to :odd
  belongs_to :settlement_initiator, optional: true, class_name: User.name

  has_one :market, through: :odd
  has_one :event, through: :market
  has_one :producer, through: :event
  has_one :title, through: :event

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

  class << self
    def with_category
      sub_query = <<~SQL
        SELECT event_scopes.name FROM event_scopes
        INNER JOIN scoped_events ON event_scopes.id = scoped_events.event_scope_id
        INNER JOIN events ON scoped_events.event_id = events.id
        INNER JOIN markets ON events.id = markets.event_id
        INNER JOIN odds ON markets.id = odds.market_id
        WHERE odds.id = bet_legs.odd_id AND
              event_scopes.kind = '#{EventScope::CATEGORY}' LIMIT 1
      SQL
      sql = "(#{sub_query}) AS category"
      select(sql)
    end

    def with_tournament
      sub_query = <<~SQL
        SELECT event_scopes.name FROM event_scopes
        INNER JOIN scoped_events ON event_scopes.id = scoped_events.event_scope_id
        INNER JOIN events ON scoped_events.event_id = events.id
        INNER JOIN markets ON events.id = markets.event_id
        INNER JOIN odds ON markets.id = odds.market_id
        WHERE odds.id = bet_legs.odd_id AND
              event_scopes.kind = '#{EventScope::TOURNAMENT}'
        LIMIT 1
      SQL
      sql = "(#{sub_query}) AS tournament"
      select(sql)
    end

    def with_sport
      sub_query = <<~SQL
        SELECT COALESCE(titles.name, titles.external_name) FROM titles
        INNER JOIN events ON events.title_id = titles.id
        INNER JOIN markets ON markets.event_id = events.id
        INNER JOIN odds ON markets.id = odds.market_id
        WHERE odds.id = bet_legs.odd_id
        LIMIT 1
      SQL
      sql = "(#{sub_query}) AS sport"
      select(sql)
    end
  end
end
