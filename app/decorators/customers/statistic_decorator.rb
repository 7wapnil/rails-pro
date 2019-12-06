# frozen_string_literal: true

module Customers
  # rubocop:disable Metrics/ClassLength
  class StatisticDecorator < ApplicationDecorator
    PRECISION = 2
    FULL_PERCENTAGE = 1
    PERCENTS_MULTIPLIER = 100
    CATEGORIES = [
      TOTAL = :total,
      TOTAL_BETS = :total_bets,
      PREMATCH = :prematch,
      LIVE_SPORTS = :live_sports,
      TOTAL_CASINO = :total_casino,
      CASINO_GAME = :casino_game,
      LIVE_CASINO = :live_casino
    ].freeze

    def last_updated_at(human: false)
      return super() unless human

      time = super() ? l(super()) : t('not_available')
      "#{Customers::Statistic.human_attribute_name(:last_updated_at)}: #{time}"
    end

    def total_bonus_awarded(human: false)
      human ? money_field(super()) : super()
    end

    def total_bonus_completed(human: false)
      human ? money_field(super()) : super()
    end

    def deposit_value(human: false)
      human ? money_field(super()) : super()
    end

    def withdrawal_value(human: false)
      human ? money_field(super()) : super()
    end

    def hold_value
      money_field(deposit_value - withdrawal_value)
    end

    def gross_gaming_revenue(category, human: false)
      amount = wager(category) - payout(category)

      human ? money_field(amount) : amount
    end

    def margin(category)
      return percentage_field(0) if gross_gaming_revenue(category).zero?
      return percentage_field(FULL_PERCENTAGE) if wager(category).zero?

      percentage_field(gross_gaming_revenue(category) / wager(category))
    end

    def wager(category, human: false)
      return 0.0 if CATEGORIES.exclude?(category)

      amount = method("#{category}_wager".to_sym).call
      human ? money_field(amount) : amount
    end

    def payout(category, human: false)
      return 0.0 if CATEGORIES.exclude?(category)

      amount = method("#{category}_payout".to_sym).call
      human ? money_field(amount) : amount
    end

    def average_wager_value(category)
      return money_field(0.0) if count_items(category).zero?

      money_field(wager(category) / count_items(category))
    end

    def count_items(category)
      return 0 if CATEGORIES.exclude?(category)

      method("#{category}_count".to_sym).call
    end

    def total_pending_bet_sum(human: false)
      human ? money_field(super()) : super()
    end

    private

    def percentage_field(value)
      number_to_percentage(value * PERCENTS_MULTIPLIER, precision: PRECISION)
    end

    def money_field(value)
      "#{number_with_precision(value, precision: PRECISION)} &#8364;".html_safe
    end

    ## TOTAL: CASINO + BETS
    def total_wager
      total_bets_wager + total_casino_wager
    end

    def total_payout
      total_bets_payout + total_casino_payout
    end

    def total_count
      total_bets_count + total_casino_count
    end

    ## ONLY BETS
    def prematch_count
      prematch_bet_count
    end

    def live_sports_count
      live_bet_count
    end

    def total_bets_wager
      prematch_wager + live_sports_wager
    end

    def total_bets_payout
      prematch_payout + live_sports_payout
    end

    def total_bets_count
      live_sports_count + prematch_count
    end

    ## ONLY CASINO
    def total_casino_wager
      casino_game_wager + live_casino_wager
    end

    def total_casino_payout
      casino_game_payout + live_casino_payout
    end

    def total_casino_count
      casino_game_count + live_casino_count
    end
  end
  # rubocop:enable Metrics/ClassLength
end
