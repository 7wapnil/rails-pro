class Event < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Visible

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
    select('events.*, COUNT(markets.id) as markets_count')
      .left_outer_joins(:markets)
      .group(:id)
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

  def self.unpopular_live
    left_outer_joins(markets: { odds: :bets })
      .where(traded_live: true)
      .where(bets: { id: nil })
      .where('events.end_at IS NOT NULL')
      .where('events.end_at < ?', Time.zone.now)
  end

  def self.unpopular_pre_live
    left_outer_joins(markets: { odds: :bets })
      .where(traded_live: false)
      .where(bets: { id: nil })
      .where('events.start_at IS NOT NULL')
      .where('events.start_at < ?', Time.zone.now)
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
  end

  def wager
    bets.sum(:amount)
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
