# frozen_string_literal: true

class Market < ApplicationRecord
  include Visible
  include StateMachines::MarketStateMachine

  before_validation :define_priority, if: :name_changed?

  PRIORITIES_MAP = [
    { pattern: /^Winner$/, priority: 0 },
    { pattern: /^1x2$/, priority: 0 }
  ].freeze

  PRIORITIES = [0, 1, 2].freeze
  DEFAULT_PRIORITY = 1

  belongs_to :event
  has_many :odds, -> { order(id: :asc) }, dependent: :destroy
  has_many :active_odds, -> { active.order(id: :asc) }, class_name: Odd.name
  has_many :bets, through: :odds
  has_many :label_joins, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_joins

  scope :with_category, -> { where.not(category: nil) }

  validates :name, :priority, presence: true

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
