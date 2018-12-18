# frozen_string_literal: true

class Market < ApplicationRecord
  include Visible

  before_validation :define_priority, if: :name_changed?
  after_create :emit_created
  after_update :emit_updated

  PRIORITIES_MAP = [
    { pattern: /^Winner$/, priority: 0 },
    { pattern: /^1x2$/, priority: 0 }
  ].freeze

  PRIORITIES = [0, 1, 2].freeze
  DEFAULT_PRIORITY = 1

  STATUSES = {
    inactive:    INACTIVE    = 'inactive',
    active:      ACTIVE      = 'active',
    suspended:   SUSPENDED   = 'suspended',
    cancelled:   CANCELLED   = 'cancelled',
    settled:     SETTLED     = 'settled',
    handed_over: HANDED_OVER = 'handed_over'
  }.freeze

  DEFAULT_STATUS = ACTIVE

  enum status: STATUSES

  belongs_to :event
  has_many :odds, -> { order(id: :asc) }, dependent: :delete_all
  has_many :bets, through: :odds
  has_many :label_joins, as: :labelable
  has_many :labels, through: :label_joins

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

  def specifier
    external_id
      .match(%r{\/.+$})
      &.to_s
      &.[](1..-1)
      &.gsub '|', ', '
  end

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
