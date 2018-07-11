class Bonus < ApplicationRecord
  enum kind: {
    deposit: 0,
    free_bet: 1
  }

  validates :code,
            :kind,
            :rollover_multiplier,
            :max_rollover_per_bet,
            :max_deposit_match,
            :min_odds_per_bet,
            :min_deposit,
            :valid_for_days,
            :expires_at,
            presence: true

  validates :code, uniqueness: { case_sensitive: false }

  validates :rollover_multiplier,
            :max_rollover_per_bet,
            :max_deposit_match,
            :min_odds_per_bet,
            :min_deposit,
            :valid_for_days,
            numericality: { greater_than: 0 }
end
