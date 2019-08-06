# frozen_string_literal: true

module Customers
  class StatisticDecorator < ApplicationDecorator
    PRECISION = 2
    FULL_PERCENTAGE = 1
    PERCENTS_MULTIPLIER = 100
    CATEGORIES = [
      TOTAL = :total,
      PREMATCH = :prematch,
      LIVE = :live
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
      amount = case category
               when TOTAL then total_wager
               when PREMATCH then prematch_wager
               when LIVE then live_sports_wager
               else 0.0
               end

      human ? money_field(amount) : amount
    end

    def payout(category, human: false)
      amount = case category
               when TOTAL then total_payout
               when PREMATCH then prematch_payout
               when LIVE then live_sports_payout
               else 0.0
               end

      human ? money_field(amount) : amount
    end

    def average_bet_value(category)
      return money_field(0.0) if bet_count(category).zero?

      money_field(wager(category) / bet_count(category))
    end

    def bet_count(category)
      case category
      when TOTAL then total_bet_count
      when PREMATCH then prematch_bet_count
      when LIVE then live_bet_count
      else 0
      end
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

    def total_wager
      prematch_wager + live_sports_wager
    end

    def total_payout
      prematch_payout + live_sports_payout
    end

    def total_bet_count
      live_bet_count + prematch_bet_count
    end
  end
end
