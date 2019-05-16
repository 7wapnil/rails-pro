# frozen_string_literal: true

module Bonuses
  class ExpiringBonusesHandler < ApplicationService
    BATCH_SIZE = 200
    PRELOAD_OPTIONS = {
      wallet: %i[currency customer bonus_balance]
    }.freeze

    def call
      CustomerBonus
        .includes(PRELOAD_OPTIONS)
        .where(expiration_reason: nil)
        .where(ended_at_sql_clause)
        .find_each(batch_size: BATCH_SIZE) { |bonus| 
          CustomerBonuses::Cancel.call(bonus: bonus)
        }
    end

    private

    def ended_at_sql_clause
      <<~SQL
        (customer_bonuses.created_at +
         INTERVAL '1' DAY * customer_bonuses.valid_for_days) < NOW()
      SQL
    end
  end
end
