class Market < ApplicationRecord
  include Visible

  before_validation :define_priority, if: :name_changed?
  after_create :emit_created
  after_update :emit_updated

  PRIORITIES_MAP = [
    { pattern: /- winner$/, priority: 1 }
  ].freeze
  PRIORITIES = [0, 1, 2].freeze
  DEFAULT_PRIORITY = 0

  STATUSES = {
    inactive: 0,
    active: 1,
    suspended: 2,
    cancelled: 3,
    settled: 4,
    handed_over: 5
  }.freeze

  DEFAULT_STATUS = STATUSES[:active]

  enum status: STATUSES

  belongs_to :event
  has_many :odds
  has_many :bets, through: :odds

  validates :name, :priority, :status, presence: true
  validates_with MarketStateValidator, restrictions: [
    %i[active cancelled],
    %i[inactive cancelled],
    %i[settled active],
    %i[settled inactive],
    %i[settled suspended],
    %i[cancelled active],
    %i[cancelled inactive],
    %i[cancelled suspended],
    %i[cancelled settled]
  ]

  private

  def emit_created
    WebSocket::Client.instance.emit(WebSocket::Signals::MARKET_CREATED,
                                    id: id.to_s,
                                    eventId: event_id.to_s)
  end

  def emit_updated
    changes = {}
    previous_changes.each do |attr, changed|
      changes[attr.to_sym] = changed[1] if %w[name status].include?(attr)
    end
    return if changes.empty?

    WebSocket::Client.instance.emit(WebSocket::Signals::MARKET_UPDATED,
                                    id: id.to_s,
                                    eventId: event_id.to_s,
                                    changes: changes)
  end

  def define_priority
    return if priority

    matched = PRIORITIES_MAP.detect do |rule|
      name =~ rule[:pattern]
    end

    self.priority = matched ? matched[:priority] : DEFAULT_PRIORITY
  end
end
