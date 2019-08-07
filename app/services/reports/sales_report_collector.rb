# frozen_string_literal: true

module Reports
  class SalesReportCollector < ApplicationService
    AMOUNT_INITIAL_VALUE = 0
    FEES = 17.5
    BONUS = :bonus
    REAL_MONEY = :real_money
    REPORT_CURRENCY = 'EUR'
    PERCENT_MULTIPLIER = 100
    PRECISION = 2

    def initialize(subject:)
      @subject = subject
    end

    def call
      report_fields
    end

    private

    attr_reader :subject

    def report_fields # rubocop:disable Metrics/MethodLength
      [
        subject.b_tag,
        ENV['BRAND'],
        Date.current.yesterday.strftime('%Y-%m-%d'),
        subject.id,
        REPORT_CURRENCY,
        0, # should be implemented in future
        deposit_real_money_converted.round(PRECISION),
        deposits_count,
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        deposit_bonus_converted.round(PRECISION),
        gross_revenue.round(PRECISION),
        bets_per_day.length,
        stake_amount.round(PRECISION),
        net_revenue.round(PRECISION)
      ]
    end

    def income_entries_per_day
      @income_entries_per_day ||= subject.income_entries
    end

    def bets_per_day
      @bets_per_day ||=
        subject.bet_entries.select { |entry| entry.bet.settled? }
    end

    def win_bets_per_day
      @win_bets_per_day ||=
        subject.win_entries.select { |entry| entry.bet.settled? }
    end

    def stake_amount
      @stake_amount ||= bets_per_day.sum(&:base_currency_amount).abs
    end

    def deposit_bonus_converted
      @deposit_bonus_converted ||= balances_calculation[BONUS]
    end

    def deposit_real_money_converted
      @deposit_real_money_converted ||= balances_calculation[REAL_MONEY]
    end

    def deposits_count
      income_entries_per_day.select(&:deposit?).length
    end

    def balances_calculation
      return @balances_calculation if @balances_calculation

      @balances_calculation = Hash.new(AMOUNT_INITIAL_VALUE)

      income_entries_per_day.each(&method(:iterate_balance_entries))

      @balances_calculation
    end

    def iterate_balance_entries(entry)
      entry.balance_entries.each(&method(:fill_hash_with_entries_amounts))
    end

    def fill_hash_with_entries_amounts(balance_entry)
      kind = balance_entry.balance.kind.to_sym

      @balances_calculation[kind] += balance_entry.base_currency_amount
    end

    def gross_revenue
      stake_amount - win_bets_per_day.sum(&:base_currency_amount)
    end

    def net_revenue
      gross_revenue - (deposit_bonus_converted +
        (deposit_real_money_converted * FEES / PERCENT_MULTIPLIER))
    end
  end
end
