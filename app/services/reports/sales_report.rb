# frozen_string_literal: true

module Reports
  class SalesReport < BaseReport
    REPORT_TYPE = 'sales'
    HEADERS = %w[BTAG	BRAND	TRANSACTION_DATE PLAYER_ID CURRENCY	Chargeback
                 DEPOSITS	DEPOSITS_Count CASINO_Bets CASINO_revenue
                 CASINO_bonuses	CASINO_stake CASINO_NGR SPORTS_BONUSES
                 SPORTS_REVENUE SPORTS_BETS	SPORTS_STAKE SPORTS_NGR].freeze

    protected

    def subject_fields(subject)
      SalesReportCollector.call(subject: subject)
    end

    def records_iterator
      Queries::SalesReportQuery.new.batch_loader do |subjects|
        subjects.each { |subject| yield subject }
      end
    end
  end
end
