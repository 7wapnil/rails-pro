# frozen_string_literal: true

class MarketTemplate < ApplicationRecord
  enum category: {
    popular: POPULAR = 'popular',
    maps: MAPS = 'maps',
    totals: TOTALS = 'totals',
    players: PLAYERS = 'players',
    handicaps: HANDICAPS = 'handicaps',
    sets: SETS = 'sets',
    halves: HALVES = 'halves',
    quarters: QUARTERS = 'quarters',
    periods: PERIODS = 'periods',
    race_to: RACE_TO = 'race_to',
    goals: GOALS = 'goals',
    corners: CORNERS = 'corners',
    innings: INNINGS = 'innings',
    score: SCORE = 'score',
    overs: OVERS = 'overs',
    penalties: PENALTIES = 'penalties',
    other: OTHER = 'other',
    game: GAME = 'game',
    frames: FRAMES = 'frames'
  }.freeze

  validates :external_id, :name, presence: true

  def variants?
    payload['variants'].present?
  end
end
