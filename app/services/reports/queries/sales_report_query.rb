# frozen_string_literal: true

module Reports
  module Queries
    # rubocop:disable Metrics/ClassLength
    class SalesReportQuery
      NO_OFFSET = 0
      MAX_ITERATIONS = 1000
      INFINITE_LOOP_MESSAGE = 'Infinite loop without break condition'
      NGR_MULTIPLIER = 0.175

      def initialize(batch_size: 5_000)
        @batch_size = batch_size
      end

      def batch_loader
        count = 0

        loop do
          count += 1
          @records = ActiveRecord::Base.connection
                                       .execute(sales_report_query)
                                       .to_a

          yield records
          break if records.length.zero? || records.length < batch_size

          raise StandardError, INFINITE_LOOP_MESSAGE if count >= MAX_ITERATIONS
        end
      end

      private

      attr_reader :batch_size, :records

      def sales_report_query
        <<~SQL
          SELECT
            customers.id AS customer_id,
            customers.b_tag AS b_tag,
            COALESCE(deposits.deposits_count, 0) AS deposits_count,
            COALESCE(deposits.real_deposits, 0) AS real_money,
            COALESCE(bets.bets_count, 0) AS bets_count,
            COALESCE(bets.stake, 0) AS sports_stake,
            (COALESCE(bonuses.bonuses, 0) + COALESCE(deposits.fee, 0)) * #{sports_ratio} AS sports_bonus_money,
            #{sports_ggr} AS sports_ggr,
            #{sports_ngr} AS sports_ngr,
            COALESCE(casino_games.casino_games_count, 0) AS casino_games_count,
            COALESCE(casino_games.stake, 0) AS casino_stake,
            (COALESCE(bonuses.bonuses, 0) + COALESCE(deposits.fee, 0)) * #{casino_ratio} AS casino_bonus_money,
            #{casino_ggr} AS casino_ggr,
            #{casino_ngr} AS casino_ngr
          FROM customers
          LEFT JOIN (#{deposits_subquery}) deposits ON deposits.customer_id = customers.id
          LEFT JOIN (#{bonuses_subquery}) bonuses ON bonuses.customer_id = customers.id
          LEFT JOIN (#{bets_subquery}) bets ON bets.customer_id = customers.id
          LEFT JOIN (#{casino_games_subquery}) casino_games ON casino_games.customer_id = customers.id
          LEFT JOIN (#{wins_subquery}) wins ON wins.customer_id = customers.id
          LEFT JOIN (#{casino_wins_subquery}) casino_wins ON casino_wins.customer_id = customers.id
          WHERE #{condition} AND #{batch_condition}
          ORDER BY customer_id
          LIMIT #{batch_size}
        SQL
      end

      def sports_ngr
        <<-SQL
          (COALESCE(bets.stake, 0) - COALESCE(wins.wins_amount, 0)) -
          ((COALESCE(bonuses.bonuses, 0) + COALESCE(deposits.fee, 0)) * #{sports_ratio} )
        SQL
      end

      def casino_ngr
        <<-SQL
          (COALESCE(casino_games.stake, 0) - COALESCE(casino_wins.wins_amount, 0)) -
          ((COALESCE(bonuses.bonuses, 0) + COALESCE(deposits.fee, 0)) * #{casino_ratio} )
        SQL
      end

      def sports_ratio
        <<-SQL
          CASE WHEN #{total_ggr} = 0 THEN 0.5
               WHEN #{sports_ggr} > 0 AND #{casino_ggr} < 0 THEN 1
               WHEN #{casino_ggr} > 0 AND #{sports_ggr} < 0 THEN 0
               ELSE #{sports_ggr} / COALESCE(#{total_ggr}, 1)
          END
        SQL
      end

      def casino_ratio
        <<-SQL
          (1.0 - #{sports_ratio})
        SQL
      end

      def sports_ggr
        <<-SQL
          (COALESCE(bets.stake, 0) - COALESCE(wins.wins_amount, 0))
        SQL
      end

      def casino_ggr
        <<-SQL
          (COALESCE(casino_games.stake, 0) - COALESCE(casino_wins.wins_amount, 0))
        SQL
      end

      def total_ggr
        <<-SQL
          (#{sports_ggr} + #{casino_ggr})
        SQL
      end

      def deposits_subquery
        <<-SQL
          SELECT
            wallets.customer_id customer_id,
            CAST(SUM(COALESCE(entries.base_currency_real_money_amount,0)) AS DECIMAL(10,2)) real_deposits,
            CAST(SUM(COALESCE(entries.base_currency_real_money_amount,0) * #{NGR_MULTIPLIER}) AS DECIMAL(10,2)) fee,
            COUNT(entries.id) as deposits_count
          FROM entries
          JOIN wallets ON wallets.id = entries.wallet_id
          WHERE entries.kind = '#{Entry::DEPOSIT}'
                AND entries.created_at BETWEEN #{recent_scope}
          GROUP BY customer_id
        SQL
      end

      def recent_scope
        "'#{Time.zone.yesterday.beginning_of_day}' AND
         '#{Time.zone.yesterday.end_of_day}'"
      end

      def bonuses_subquery
        <<-SQL
          SELECT
            wallets.customer_id customer_id,
            CAST(SUM(COALESCE(entries.base_currency_bonus_amount,0)) AS DECIMAL(10,2)) bonuses
          FROM entries
          JOIN wallets ON wallets.id = entries.wallet_id
          WHERE entries.kind in (#{Entry::INCOME_ENTRY_KINDS.map { |a| "'#{a}'" }.join(', ')})
                AND entries.created_at BETWEEN #{recent_scope}
                AND entries.base_currency_bonus_amount > 0
          GROUP BY customer_id
        SQL
      end

      def bets_subquery
        <<-SQL
          SELECT
            bets.customer_id customer_id,
            CAST(SUM(COALESCE(ABS(entries.base_currency_amount),0)) AS DECIMAL(10,2)) stake,
            count(entries.id) bets_count
          FROM entries
          JOIN bets ON bets.id = entries.origin_id AND bets.status = '#{Bet::SETTLED}' AND bets.settlement_status != '#{Bet::VOIDED}'
          WHERE bets.bet_settlement_status_achieved_at BETWEEN #{recent_scope}
                AND entries.kind = '#{Entry::BET}'
                AND entries.confirmed_at IS NOT NULL
          GROUP BY bets.customer_id
        SQL
      end

      def casino_games_subquery
        <<-SQL
          SELECT
            wallets.customer_id,
            CAST(SUM(COALESCE(ABS(entries.base_currency_amount),0)) AS DECIMAL(10,2)) stake,
            count(entries.id) casino_games_count
          FROM entries
          JOIN wallets ON wallets.id = entries.wallet_id
          WHERE entries.created_at BETWEEN #{recent_scope} AND entries.kind = '#{Entry::EVERY_MATRIX_WAGER}'
          GROUP BY wallets.customer_id
        SQL
      end

      def wins_subquery
        <<-SQL
          SELECT
            bets.customer_id customer_id,
            CAST(SUM(COALESCE(entries.base_currency_amount,0)) AS DECIMAL(10,2)) wins_amount
          FROM entries
          JOIN bets ON bets.id = entries.origin_id AND bets.status = '#{Bet::SETTLED}' AND bets.settlement_status != '#{Bet::VOIDED}'
          WHERE entries.created_at BETWEEN#{recent_scope} AND entries.kind = '#{Entry::WIN}'
          GROUP BY bets.customer_id
        SQL
      end

      def casino_wins_subquery
        <<-SQL
          SELECT
            wallets.customer_id customer_id,
            CAST(SUM(COALESCE(entries.base_currency_amount,0)) AS DECIMAL(10,2)) wins_amount
          FROM entries
          JOIN wallets ON wallets.id = entries.wallet_id
          WHERE entries.created_at BETWEEN#{recent_scope} AND entries.kind = '#{Entry::EVERY_MATRIX_RESULT}'
          GROUP BY customer_id
        SQL
      end

      def condition
        'customers.b_tag IS NOT NULL AND (wins IS NOT NULL
         OR bets IS NOT NULL  OR deposits IS NOT NULL OR bonuses IS NOT NULL
         OR casino_games IS NOT NULL)'
      end

      def batch_condition
        "customers.id > #{offset}"
      end

      def offset
        return NO_OFFSET unless records

        # not an array, but PG::Result object, does not support [-1]
        records[records.length - 1]['customer_id']
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
