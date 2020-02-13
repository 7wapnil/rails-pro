# frozen_string_literal: true

module Withdrawals
  class PendingAmount < ApplicationService
    QUERY = 'COALESCE(base_currency_amount, 0.0)'

    def call
      Withdrawal
        .where(status: :pending)
        .joins(:entry)
        .pluck(Arel.sql(QUERY))
        .reduce(:+)
        .to_f
        .truncate(primary_scale)
        .to_d
    end

    private

    def primary_scale
      @primary_scale ||= Currency.primary_scale
    end
  end
end
