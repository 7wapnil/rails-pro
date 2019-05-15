# frozen_string_literal: true

module Reports
  class SalesReport < BaseReport
    REPORT_TYPE = 'sales'
    HEADERS = %w[BTAG	BRAND	TRANSACTION_DATE	PLAYER_ID	CURRENCY	Chargeback
                 DEPOSITS	DEPOSITS_Count	CASINO_Bets	CASINO_revenue
                 CASINO_bonuses	CASINO_stake	CASINO_NGR	SPORTS_BONUSES
                 SPORTS_REVENUE	SPORTS_BETS	SPORTS_STAKE	SPORTS_NGR].freeze

    protected

    def subject_fields(subject)
      SalesReportCollector.call(subject: subject)
    end

    def subjects
      Customer
        .where
        .not(b_tag: nil)
        .left_joins(:entries)
        .where(query_string, *query_params)
        .distinct
    end

    private

    def query_string
      '(DATE(entries.created_at) = ? AND entries.kind = ?) OR
       (DATE(entries.created_at) = ? AND entries.kind = ?)'
    end

    def query_params
      [Date.current.yesterday, EntryKinds::BET,
       Date.current.yesterday, EntryKinds::DEPOSIT]
    end
  end
end
