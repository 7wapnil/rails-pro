# frozen_string_literal: true

module Customers
  class Statistic < ApplicationRecord
    self.table_name = 'customer_statistics'

    CATEGORIES = [
      TOTAL = :total,
      PREMATCH = :prematch,
      LIVE = :live
    ].freeze

    belongs_to :customer, inverse_of: :statistics

    def hold_value
      deposit_value - withdrawal_value
    end

    def gross_gaming_revenue(category)
      wager(category) - payout(category)
    end

    def margin(category)
      return 0.0 if wager(category).zero?

      gross_gaming_revenue(category) / wager(category)
    end

    def wager(category)
      case category
      when TOTAL then total_wager
      when PREMATCH then prematch_wager
      when LIVE then live_sports_wager
      else 0.0
      end
    end

    def total_wager
      prematch_wager + live_sports_wager
    end

    def payout(category)
      case category
      when TOTAL then total_payout
      when PREMATCH then prematch_payout
      when LIVE then live_sports_payout
      else 0.0
      end
    end

    def total_payout
      prematch_payout + live_sports_payout
    end

    def average_bet_value(category)
      return 0.0 if bet_count(category).zero?

      wager(category) / bet_count(category)
    end

    def bet_count(category)
      case category
      when TOTAL then total_bet_count
      when PREMATCH then prematch_bet_count
      when LIVE then live_bet_count
      else 0
      end
    end

    def total_bet_count
      live_bet_count + prematch_bet_count
    end

    # TODO: place formula here
    def total_bonus_value
      0.0
    end
  end
end
