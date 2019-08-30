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

    def report_fields # rubocop:disable Metrics/MethodLength
      [
        subject['b_tag'],
        ENV['BRAND'],
        Date.current.yesterday.strftime('%Y-%m-%d'),
        subject['customer_id'],
        REPORT_CURRENCY,
        0, # should be implemented in future
        subject['real_money'],
        subject['deposits_count'],
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        0, # should be implemented in future
        subject['bonus_money'],
        subject['ggr'],
        subject['bets_count'],
        subject['stake'],
        subject['ngr']
      ]
    end
  end
end
