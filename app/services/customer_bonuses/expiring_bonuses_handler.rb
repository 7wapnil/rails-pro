# frozen_string_literal: true

module CustomerBonuses
  class ExpiringBonusesHandler < ApplicationService
    BATCH_SIZE = 200
    PRELOAD_OPTIONS = {
      wallet: %i[currency customer bonus_balance]
    }.freeze

    def call
      expiring_bonuses = CustomerBonus.includes(PRELOAD_OPTIONS)
                                      .where(status: CustomerBonus::ACTIVE)
      expiring_bonuses.find_each(batch_size: BATCH_SIZE) do |bonus|
        next unless bonus.time_exceeded?

        CustomerBonuses::Deactivate.call(
          bonus: bonus,
          action: CustomerBonuses::Deactivate::EXPIRE
        )
      end
    end
  end
end
