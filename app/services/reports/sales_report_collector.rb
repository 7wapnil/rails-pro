# frozen_string_literal: true

module Reports
  # rubocop:disable Metrics/ClassLength
  class SalesReportCollector < ApplicationService
    AMOUNT_INITIAL_VALUE = 0
    FEES = 17.5
    BONUS = :bonus
    REAL_MONEY = :real_money
    REPORT_CURRENCY = 'EUR'
    PERCENT_MULTIPLIER = 100

    def initialize(subject:, target_currency:)
      @subject = subject
      @target_currency = target_currency
    end

    def call
      report_fields
    end

    private

    attr_reader :subject, :target_currency

    def report_fields # rubocop:disable Metrics/MethodLength
      [
        subject.b_tag,
        ENV['BRAND'],
        Date.current.yesterday.strftime('%Y-%m-%d'),
        subject.id,
        REPORT_CURRENCY,
        0, # should be implemented in future
        deposit_real_money_converted,
        deposits_count,
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        deposit_bonus_converted,
        gross_revenue,
        bets_per_day.length,
        stake_amount,
        net_revenue
      ]
    end

    def income_entries_per_day
      @income_entries_per_day ||= subject.income_entries
    end

    def bets_per_day
      @bets_per_day ||= subject.bet_entries
    end

    def win_bets_per_day
      @win_bets_per_day ||= subject.win_entries
    end

    def subject_currency
      @subject_currency ||= subject.wallet.currency
    end

    def deposit_amount
      Exchanger::Converter.call(
        income_entries_per_day.sum(&:amount), subject_currency, target_currency
      )
    end

    def stake_amount
      Exchanger::Converter.call(
        bets_per_day.sum(&:amount).abs,
        subject_currency,
        target_currency
      )
    end

    def deposit_bonus_converted
      Exchanger::Converter.call(
        balances_calculation[BONUS],
        subject_currency,
        target_currency
      )
    end

    def deposit_real_money_converted
      Exchanger::Converter.call(
        balances_calculation[REAL_MONEY],
        subject_currency,
        target_currency
      )
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

      @balances_calculation[kind] += balance_entry.amount
    end

    def gross_revenue
      @gross_revenue ||=
        Exchanger::Converter
        .call(gross_revenue_amount, subject_currency, target_currency)
    end

    def gross_revenue_amount
      bets_per_day.sum(&:amount).abs - win_bets_per_day.sum(&:amount)
    end

    def net_revenue
      gross_revenue - (deposit_bonus_converted +
        (deposit_real_money_converted * FEES / PERCENT_MULTIPLIER))
    end
    # rubocop:enable Metrics/ClassLength
  end
end
