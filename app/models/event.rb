# frozen_string_literal: true

class Event < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Visible
  include Importable
  include EventScopeAssociations

  conflict_target :external_id
  conflict_updatable :name,
                     :status,
                     :traded_live,
                     :display_status,
                     :home_score,
                     :away_score,
                     :time_in_seconds,
                     :liveodds

  UPDATABLE_ATTRIBUTES = %w[
    name
    description
    start_at
    end_at
    display_status
    home_score
    away_score
    time_in_seconds
    liveodds
  ].freeze

  # 4 hours ago is a temporary workaround to reduce amount of live events
  # Will be removed when proper event ending logic is implemented
  START_AT_OFFSET_IN_HOURS = 4
  UPCOMING_LIMIT = 16
  UPCOMING_DURATION = 6

  PRIORITIES = [0, 1, 2].freeze

  STATUSES = {
    not_started: NOT_STARTED = 'not_started',
    started:     STARTED     = 'started',
    suspended:   SUSPENDED   = 'suspended',
    ended:       ENDED       = 'ended',
    closed:      CLOSED      = 'closed',
    cancelled:   CANCELLED   = 'cancelled',
    delayed:     DELAYED     = 'delayed',
    interrupted: INTERRUPTED = 'interrupted',
    postponed:   POSTPONED   = 'postponed',
    abandoned:   ABANDONED   = 'abandoned'
  }.freeze

  IN_PLAY_STATUSES = [STARTED, SUSPENDED]

  BOOKABLE = 'bookable'

  START_STATUSES = [
    UPCOMING = 'upcoming',
    LIVE = 'live'
  ].freeze

  ransacker :markets_count do
    Arel.sql('markets_count')
  end

  ransacker :bets_count do
    Arel.sql('bets_count')
  end

  ransacker :wager do
    Arel.sql('wager')
  end

  scope :active, -> { where(active: true) }

  belongs_to :title
  belongs_to :producer,
             class_name: Radar::Producer.name,
             inverse_of: :events,
             optional: true
  has_many :markets, dependent: :destroy
  has_many :categorized_markets,
           -> { for_displaying.with_category },
           class_name: Market.name
  has_many :bets, through: :markets
  has_many :scoped_events, dependent: :delete_all
  has_many :event_scopes, through: :scoped_events
  has_many :label_joins, as: :labelable
  has_many :labels, through: :label_joins
  has_many :event_competitors, dependent: :delete_all
  has_many :competitors, through: :event_competitors
  has_many :players, through: :competitors

  has_many :dashboard_markets, -> { for_displaying }, class_name: Market.name

  validates :name, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :active, inclusion: { in: [true, false] }

  enum status: STATUSES

  delegate :name, to: :title, prefix: true

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
        WHERE markets.event_id = events.id AND customers.account_kind = '#{Customer::REGULAR}' LIMIT 1)
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
        WHERE markets.event_id = events.id AND customers.account_kind = '#{Customer::REGULAR}' LIMIT 1)
    SQL
    select("events.*, #{sub_query} as wager").group(:id)
  end

  def self.upcoming(limit_start_at: nil)
    start_at_upper_limit = limit_start_at || DateTime::Infinity.new
    start_at_range = Time.zone.now..start_at_upper_limit

    where(start_at: start_at_range, end_at: nil)
  end

  def self.in_play
    where(status: IN_PLAY_STATUSES, traded_live: true)
  end

  def self.past
    where(
      [
        'start_at < ? AND ',
        'traded_live IS FALSE OR ',
        'end_at < ? AND ',
        'traded_live IS TRUE'
      ].join,
      Time.zone.now,
      Time.zone.now
    )
  end

  def self.today
    where(start_at: [Date.today.beginning_of_day..Date.today.end_of_day])
  end

  def to_s
    name
  end

  def categories
    categorized_markets.group_by(&:category).map do |category, markets|
      OpenStruct.new(id: "#{id}:#{category}",
                     name: I18n.t("market_categories.#{category}"),
                     count: markets.length)
    end
  end

  def start_status
    return LIVE if alive?

    UPCOMING if upcoming?
  end

  def upcoming?
    start_at > Time.zone.now && !end_at
  end

  def upcoming_for_time?
    upcoming? && start_at < UPCOMING_DURATION.hours.from_now
  end

  def in_play?(limited: false)
    traded_live && start_at.past? && end_at.nil? &&
      (!limited || start_at > START_AT_OFFSET_IN_HOURS.hours.ago)
  end

  def update_from!(other)
    unless other.is_a?(self.class)
      raise TypeError, 'Passed \'other\' argument is not an Event'
    end

    assign_attributes(other.attributes.slice(*UPDATABLE_ATTRIBUTES))

    save!
    self
  end

  def alive?
    traded_live? && (in_play?(limited: true) || suspended?)
  end

  def score
    return unless home_score && away_score

    "#{home_score}:#{away_score}"
  end

  def bookable?
    liveodds == BOOKABLE
  end
end
