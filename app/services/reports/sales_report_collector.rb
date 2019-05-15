# frozen_string_literal: true

module Reports
  class SalesReportCollector < ApplicationService
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
        Date.current.yesterday.strftime('%d/%m/%Y'),
        subject.id,
        subject_currency,
        'Chargeback', # should be implemented in future
        deposit_real_money_converted,
        deposits_per_day.length,
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        deposit_bonus_converted,
        gross_revenue,
        bets_per_day.length,
        stake_amount,
        'net revenue' # should be implemented in future
      ]
    end

    def deposits_per_day
      @deposits_per_day ||= subject
                            .entries
                            .deposit
                            .where('DATE(entries.created_at) = ?',
                                   Date.current.yesterday)
    end

    def bets_per_day
      @bets_per_day ||= subject
                        .entries
                        .bet
                        .where('DATE(entries.created_at) = ?',
                               Date.current.yesterday)
    end

    def win_bets_per_day
      @win_bets_per_day ||= subject
                            .entries
                            .win
                            .where('DATE(entries.created_at) = ?',
                                   Date.current.yesterday)
    end

    def subject_currency
      @subject_currency ||= subject.currencies.first
    end

    def deposit_amount
      Exchanger::Converter.call(
        deposits_per_day.sum(:amount), subject_currency.code
      )
    end

    def stake_amount
      Exchanger::Converter.call(
        bets_per_day.sum(:amount).abs, subject_currency.code
      )
    end

    def deposit_bonus_converted
      Exchanger::Converter.call(deposit_bonus, subject_currency.code)
    end

    def deposit_real_money_converted
      Exchanger::Converter.call(deposit_real_money, subject_currency.code)
    end

    def deposit_bonus
      deposits_per_day.sum { |entry| entry.bonus_balance_entry&.amount || 0 }
    end

    def deposit_real_money
      deposits_per_day.sum { |entry| entry.real_money_balance_entry.amount }
    end

    def gross_revenue
      Exchanger::Converter
        .call(gross_revenue_amount, subject_currency.code)
    end

    def gross_revenue_amount
      bets_per_day.sum(:amount).abs - win_bets_per_day.sum(:amount)
    end
  end
end
