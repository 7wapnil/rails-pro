# frozen_string_literal: true

module Reports
  module Queries
    class MonthlyBalanceQuery < ApplicationService
      def call
        ActiveRecord::Base.connection.execute(monthly_balance_query)
      end

      private

      def monthly_balance_query
        <<~SQL
          INSERT INTO
            monthly_balance_query_results (
              real_money_balance_eur,
              bonus_amount_balance_eur,
              total_balance_eur,
              created_at,
              updated_at
            )
          SELECT
            sum(ent.real_money_balance_eur) AS real_money_balance_eur,
            sum(ent.bonus_amount_balance_eur) AS bonus_amount_balance_eur,
            sum(ent.total_balance_eur) AS total_balance_eur,
            now() AS created_at,
            now() AS updated_at
          FROM (
            SELECT
              e.id,
              w.customer_id AS custid,
              w.currency_id,
              c.name,
              c.exchange_rate,
              (e.balance_amount_after - bonus_amount_after) / c.exchange_rate
                AS real_money_balance_eur,
              bonus_amount_after  / c.exchange_rate
                AS bonus_amount_balance_eur,
              balance_amount_after / c.exchange_rate
                AS total_balance_eur
            FROM
              entries e
            JOIN wallets w
            ON e.wallet_id = w.id
            JOIN currencies c
            ON c.id = w.currency_id
          ) ent
          JOIN (
            SELECT
              wallet_id,
              max(id) AS id
            FROM
              entries
            GROUP BY 1
          ) max
          ON max.id = ent.id;
        SQL
      end
    end
  end
end
