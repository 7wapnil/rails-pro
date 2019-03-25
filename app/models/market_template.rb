# frozen_string_literal: true

class MarketTemplate < ApplicationRecord
  enum category: {
    popular: POPULAR = 'popular',
    maps: MAPS = 'maps',
    totals: TOTALS = 'totals',
    players: PLAYERS = 'players',
    specials: SPECIALS = 'specials',
    handicaps: HANDICAPS = 'handicaps',
    objectives: OBJECTIVES = 'objectives',
    matches: MATCHES = 'matches',
    sets: SETS = 'sets',
    fast: FAST = 'fast',
    general: GENERAL = 'general',
    halves: HALVES = 'halves',
    quarters: QUARTERS = 'quarters',
    full_time: FULL_TIME = 'full_time',
    regular_time: REGULAR_TIME = 'regular_time',
    full_time_overtime: FULL_TIME_OVERTIME = 'full_time_overtime',
    periods: PERIODS = 'periods',
    race_to: RACE_TO = 'race_to',
    goalscorer: GOALSCORER = 'goalscorer',
    player_stats: PLAYER_STATS = 'player_stats',
    goals: GOALS = 'goals',
    corners: CORNERS = 'corners',
    cards: CARDS = 'cards',
    asian_lines: ASIAN_LINES = 'asian_lines'
  }.freeze

  validates :external_id, :name, presence: true

  def variants?
    payload['variants'].present?
  end
end
