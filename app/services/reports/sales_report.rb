# frozen_string_literal: true

module Reports
  class SalesReport < BaseReport
    REPORT_TYPE = 'sales'
    HEADERS = %w[BTAG	BRAND	TRANSACTION_DATE	PLAYER_ID	CURRENCY	Chargeback
                 DEPOSITS	DEPOSITS_Count	CASINO_Bets	CASINO_revenue
                 CASINO_bonuses	CASINO_stake	CASINO_NGR	SPORTS_BONUSES
                 SPORTS_REVENUE	SPORTS_BETS	SPORTS_STAKE	SPORTS_NGR].freeze

    PRELOAD_OPTIONS = %i[bet_entries win_bet_entries].freeze
    INCLUDES_OPTIONS = {
      wallet: :currency,
      deposit_entries:
       {
         balance_entries: :balance
       }
    }.freeze

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
        .includes(**INCLUDES_OPTIONS)
        .references(:deposit_entries)
        .where(query_string, *query_params)
        .distinct
    end

    private

    def query_string
      "(#{date_range_query} AND entries.kind = ?) OR
       (#{date_range_query} AND entries.kind = ?) OR
       (#{date_range_query} AND entries.kind = ?)"
    end

    def query_params
      [*date_range, EntryKinds::BET,
       *date_range, EntryKinds::DEPOSIT,
       *date_range, EntryKinds::WIN]
    end

    def primary_currency
      @primary_currency ||= Currency.primary
    end

    def date_range
      [Time.zone.yesterday.beginning_of_day,
       Time.zone.yesterday.end_of_day]
    end

    def date_range_query
      'entries.created_at > ? AND entries.created_at < ?'
    end
  end
end
