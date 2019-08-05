# frozen_string_literal: true

module Reports
  class SalesReport < BaseReport
    REPORT_TYPE = 'sales'
    HEADERS = %w[BTAG	BRAND	TRANSACTION_DATE PLAYER_ID CURRENCY	Chargeback
                 DEPOSITS	DEPOSITS_Count CASINO_Bets CASINO_revenue
                 CASINO_bonuses	CASINO_stake CASINO_NGR SPORTS_BONUSES
                 SPORTS_REVENUE SPORTS_BETS	SPORTS_STAKE SPORTS_NGR].freeze

    PRELOAD_OPTIONS = [
      bet_entries: :bet,
      win_entries: :bet,
      income_entries: {
        balance_entries: :balance
      }
    ].freeze

    protected

    def subject_fields(subject)
      SalesReportCollector.call(subject: subject)
    end

    def subjects
      @subjects ||= Customer
                    .where
                    .not(b_tag: nil)
                    .eager_load(*PRELOAD_OPTIONS)
                    .where(query_string, *query_params)
                    .distinct
    end

    private

    def query_string
      "(#{bet_entries_table}.kind = ? AND
        bets.status = 'settled') OR
       (#{win_entries_table}.kind = ? AND
        bets_entries.status = 'settled') OR
       ((bets_entries.id IS NULL AND bets.id IS NULL) AND
       (#{income_entries_table}.kind = ? OR
       #{income_entries_table}.kind = ?))"
    end

    # This methods should be used to specify correct table name

    def bet_entries_table
      'entries'
    end

    def win_entries_table
      'win_entries_customers'
    end

    def income_entries_table
      'income_entries_customers'
    end

    def query_params
      [EntryKinds::BET,
       EntryKinds::WIN,
       EntryKinds::DEPOSIT, EntryKinds::BONUS_CHANGE]
    end
  end
end
