# frozen_string_literal: true

class Market < ApplicationRecord
  include Visible

  before_validation :define_priority, if: :name_changed?

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

  DISPLAYED_STATUSES = [ACTIVE, SUSPENDED].freeze

  DEFAULT_STATUS = ACTIVE

  enum status: STATUSES

  belongs_to :event
  has_many :odds, -> { order(id: :asc) }, dependent: :delete_all
  has_many :active_odds, -> { active.order(id: :asc) }, class_name: Odd.name
  has_many :bets, through: :odds
  has_many :label_joins, as: :labelable
  has_many :labels, through: :label_joins

  scope :with_category, -> { where.not(category: nil) }

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

  def self.for_displaying
    visible
      .joins(:odds)
      .group('markets.id')
      .where('markets.status' => DISPLAYED_STATUSES)
      .order(priority: :asc, id: :asc)
  end

  private

  def define_priority
    return if priority

    matched = PRIORITIES_MAP.detect do |rule|
      name =~ rule[:pattern]
    end

    self.priority = matched ? matched[:priority] : DEFAULT_PRIORITY
  end
end
