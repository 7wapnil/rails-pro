# frozen_string_literal: true

module Reports
  module Queries
    class DailyStatsQuery < ApplicationService
      def call
        ActiveRecord::Base.connection.execute(daily_stats_query).to_a.first
      end

      private

      def daily_stats_query
        <<~SQL
          select
          	*
          from
            daily_report_date,
            daily_signups,
            daily_signups_affiliated,
            daily_ftds,
            daily_ftds_affiliated,
            daily_deposits,
            daily_withdrawals,
            daily_sport_bets,
            daily_sport_wins,
            daily_sports_ggr,
            daily_pending_bets,
            daily_casino_bets,
            daily_casino_wins,
            daily_casino_ggr,
            daily_total_ggr,
            daily_bonus_awarded,
            daily_deposit_fails,
            daily_ratios;
        SQL
      end
    end
  end
end
