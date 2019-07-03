# frozen_string_literal: true

class Bonus < ApplicationRecord
  enum kind: {
    deposit:  DEPOSIT  = 'deposit',
    free_bet: FREE_BET = 'free_bet'
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
            :percentage,
            presence: true

  validates :percentage, numericality: { greater_than_or_equal_to: 0 }
  validates :code, uniqueness: { case_sensitive: false }

  validates :rollover_multiplier,
            :max_rollover_per_bet,
            :max_deposit_match,
            :min_odds_per_bet,
            :min_deposit,
            :valid_for_days,
            numericality: { greater_than: 0 }

  acts_as_paranoid

  has_many :customer_bonuses, foreign_key: :original_bonus_id

  scope :active, -> { where('bonuses.expires_at > ?', Time.zone.now) }

  def active?
    expires_at > Time.zone.now
  end

  class << self
    def from_code(code)
      active.find_by('lower(code) = ?', code.downcase)
    end
  end
end
