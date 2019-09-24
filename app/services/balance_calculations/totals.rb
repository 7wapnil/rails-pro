# frozen_string_literal: true

module BalanceCalculations
  class Totals < ApplicationService
    PRECISION = 2
    BALANCE_SELECT_QUERY = <<~SQL
      SUM(
        wallets.real_money_balance / COALESCE(currencies.exchange_rate, 1.0)
      ) as real_money_balance,
      SUM(
        wallets.bonus_balance / COALESCE(currencies.exchange_rate, 1.0)
      ) as bonus_balance
    SQL

    def call
      {
        real_money: humanize_amount(balance.real_money_balance),
        bonus: humanize_amount(balance.bonus_balance)
      }
    end

    private

    def balance
      @balance ||= Wallet
                   .joins(:currency)
                   .select(BALANCE_SELECT_QUERY)
                   .load
                   .first
    end

    def humanize_amount(amount)
      return 0.0 unless amount

      ::Currency::PRIMARY_RATE * amount.truncate(PRECISION)
    end
  end
end
