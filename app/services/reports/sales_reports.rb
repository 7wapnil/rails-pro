# frozen_string_literal: true

module Reports
  class SalesReports < BaseReport
    REPORT_TYPE = 'sales'
    HEADERS = %w[BTAG	BRAND	TRANSACTION_DATE	PLAYER_ID	CURRENCY	Chargeback
                 DEPOSITS	DEPOSITS_Count	CASINO_Bets	CASINO_revenue
                 CASINO_bonuses	CASINO_stake	CASINO_NGR	SPORTS_BONUSES
                 SPORTS_REVENUE	SPORTS_BETS	SPORTS_STAKE	SPORTS_NGR].freeze

    PRELOAD_OPTIONS = [
      :bet_entries,
      :win_bet_entries,
      deposit_entries: :balance_entries
    ].freeze

    protected

    def subject_fields(subject)
      SalesReportCollector.call(subject: subject,
                                target_currency: primary_currency)
    end

    def subjects
      Customer
        .where
        .not(b_tag: nil)
        .left_joins(*PRELOAD_OPTIONS)
        .includes(wallet: :currency)
        .where(query_string, *query_params)
        .distinct
    end

    private

    def query_string
      '(DATE(entries.created_at) = ? AND entries.kind = ?) OR
       (DATE(entries.created_at) = ? AND entries.kind = ?) OR
       (DATE(entries.created_at) = ? AND entries.kind = ?)'
    end

    def query_params
      [Date.current.yesterday, EntryKinds::BET,
       Date.current.yesterday, EntryKinds::DEPOSIT,
       Date.current.yesterday, EntryKinds::WIN]
    end

    def primary_currency
      @primary_currency ||= Currency.primary
    end
  end
end
