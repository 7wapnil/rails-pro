# frozen_string_literal: true

class Market < ApplicationRecord
  include Visible
  include StateMachines::MarketStateMachine

  before_validation :define_priority, if: :name_changed?

  PRIORITIES = [
    HIGH_PRIORITY = 0,
    DEFAULT_PRIORITY = 1,
    LOW_PRIORITY = 2
  ].freeze

  PRIORITIES_MAP = [
    { pattern: /^Winner$/, priority: HIGH_PRIORITY },
    { pattern: /^1x2$/, priority: HIGH_PRIORITY }
  ].freeze

  belongs_to :event
  belongs_to :template, class_name: MarketTemplate.name,
                        optional: true,
                        inverse_of: :markets

  has_many :odds, -> { order(id: :asc) }, dependent: :destroy
  has_many :bets, through: :odds
  has_many :label_joins, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_joins

  validates :name, :priority, presence: true

  def self.with_category
    eager_load(:template).where.not(market_templates: { category: nil })
  end

  def specifier
    external_id
      .match(%r{\/.+$})
      &.to_s
      &.[](1..-1)
      &.gsub '|', ', '
  end

  def self.for_displaying
    visible
      .where(markets: { status: DISPLAYED_STATUSES })
      .or(
        where(markets: { priority: HIGH_PRIORITY })
      )
      .eager_load(:template)
      .joins(:odds)
      .group('markets.id, market_templates.id')
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
