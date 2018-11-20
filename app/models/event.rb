class Event < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Visible
  include HasUniqueExternalId

  after_create :emit_created
  after_update :emit_updated

  UPDATABLE_ATTRIBUTES = %w[name description start_at end_at].freeze

  PRIORITIES = [0, 1, 2].freeze

  STATUSES = {
    not_started: 0,
    started: 1,
    ended: 2,
    closed: 3
  }.freeze

  ransacker :markets_count do
    Arel.sql('markets_count')
  end

  ransacker :bets_count do
    Arel.sql('bets_count')
  end

  ransacker :wager do
    Arel.sql('wager')
  end

  belongs_to :title
  has_many :markets, dependent: :delete_all
  has_many :bets, through: :markets
  has_many :scoped_events, dependent: :delete_all
  has_many :event_scopes, through: :scoped_events
  has_many :label_joins, as: :labelable
  has_many :labels, through: :label_joins

  validates :name, presence: true
  validates :priority, inclusion: { in: PRIORITIES }

  enum status: STATUSES

  delegate :name, to: :title, prefix: true

  def self.start_time_offset
    4.hours.ago
  end

  def self.with_markets_count
    query = <<-SQL
      events.*,
      (SELECT COUNT(markets.id) from markets WHERE markets.event_id = events.id) as markets_count
    SQL
    select(query).group(:id)
  end

  def self.with_bets_count
    sub_query = <<~SQL
      (SELECT COUNT(bets.id) FROM bets
        INNER JOIN customers ON customers.id = bets.customer_id
        INNER JOIN odds ON odds.id = bets.odd_id
        INNER JOIN markets ON markets.id = odds.market_id
        WHERE markets.event_id = events.id AND customers.account_kind = #{Customer.account_kinds[:regular]} LIMIT 1)
    SQL
    select("events.*, #{sub_query} as bets_count")
      .group(:id)
  end

  def self.with_wager
    sub_query = <<~SQL
      (SELECT COALESCE(SUM(bets.amount) ,0) FROM bets
        INNER JOIN customers ON customers.id = bets.customer_id
        INNER JOIN odds ON odds.id = bets.odd_id
        INNER JOIN markets ON markets.id = odds.market_id
        WHERE markets.event_id = events.id AND customers.account_kind = #{Customer.account_kinds[:regular]} LIMIT 1)
    SQL
    select("events.*, #{sub_query} as wager").group(:id)
  end

  def self.upcoming
    where('start_at > ? AND end_at IS NULL', Time.zone.now)
  end

  # 4 hours ago is a temporary workaround to reduce amount of live events
  # Will be removed when proper event ending logic is implemented
  def self.in_play
    where(
      [
        'start_at < ? AND ',
        'start_at > ? AND ',
        'end_at IS NULL AND ',
        'traded_live IS TRUE'
      ].join,
      Time.zone.now,
      start_time_offset
    )
  end

  def self.today
    where(start_at: [Date.today.beginning_of_day..Date.today.end_of_day])
  end

  def in_play?
    traded_live && start_at.past? && end_at.nil?
  end

  def update_from!(other)
    unless other.is_a?(self.class)
      raise TypeError, 'Passed \'other\' argument is not an Event'
    end

    assign_attributes(other.attributes.slice(*UPDATABLE_ATTRIBUTES))
    add_to_payload(other.payload)

    save!
    self
  end

  # This is a good candidate to be extracted to a reusable concern
  def add_to_payload(addition)
    return unless addition

    payload&.merge!(addition)
    self.payload = addition unless payload

    return unless addition[:event_status]

    WebSocket::Client.instance.emit(
      WebSocket::Signals::EVENT_UPDATED,
      id: id.to_s,
      changes: { event_status: addition[:event_status] }
    )
  end

  def tournament
    event_scopes.where(kind: :tournament).first
  end

  def details
    ::EventDetails::Factory.build(self)
  end

  private

  def emit_created
    WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_CREATED,
                                    id: id.to_s)
  end

  def emit_updated
    excluded_keys = %w[updated_at payload]
    changes = previous_changes
              .except(*excluded_keys)
              .transform_values! { |v| v[1] }
    return if changes.empty?

    WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_UPDATED,
                                    id: id.to_s,
                                    changes: changes)
  end
end
