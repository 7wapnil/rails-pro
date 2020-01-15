# frozen_string_literal: true

module Reports
  class SalesReportCollector < ApplicationService
    REPORT_CURRENCY = 'EUR'

    def initialize(subject:)
      @subject = subject
    end

    def call
      report_fields
    end

    private

    attr_reader :subject

    def report_fields # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      [
        subject['b_tag'],
        ENV['BRAND'],
        Date.current.yesterday.strftime('%Y-%m-%d'),
        subject['customer_id'],
        REPORT_CURRENCY,
        0, # should be implemented in future
        subject['real_money'],
        subject['deposits_count'],
        subject['casino_games_count'],
        subject['casino_ggr'],
        subject['casino_bonus_money'],
        subject['casino_stake'],
        subject['casino_ngr'],
        subject['sports_bonus_money'],
        subject['sports_ggr'],
        subject['bets_count'],
        subject['sports_stake'],
        subject['sports_ngr']
      ]
    end
  end
end
