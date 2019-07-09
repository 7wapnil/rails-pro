# frozen_string_literal: true

module Withdrawals
  class PendingAmount < ApplicationService
    PRECISION = 2
    QUERY = 'COALESCE(base_currency_amount, 0.0)'

    def call
      Withdrawal
        .where(status: :pending)
        .joins(:entry)
        .pluck(Arel.sql(QUERY))
        .reduce(:+)
        .to_f
        .truncate(PRECISION)
        .to_d
    end
  end
end
