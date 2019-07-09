# frozen_string_literal: true

module BalanceCalculations
  class Totals < ApplicationService
    PRECISION = 2
    QUERY = <<~SQL
      COALESCE(balances.amount, 0.0) / COALESCE(currencies.exchange_rate, 1.0)
    SQL

    def call
      Balance.kinds.transform_values do |kind|
        ::Currency::PRIMARY_RATE *
          Balance
          .where(kind: kind)
          .joins(wallet: :currency)
          .pluck(Arel.sql(QUERY))
          .reduce(:+)
          .to_f
          .truncate(PRECISION)
          .to_d
      end
    end
  end
end
