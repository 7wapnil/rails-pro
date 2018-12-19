module Scheduled
  class ExpiringBonusesWorker < ApplicationWorker
    sidekiq_options queue: 'expired_bonuses',
                    lock: :until_executed

    def perform
      super()

      CustomerBonus
        .where(expiration_reason: nil)
        .select(&:expired?)
        .each do |bonus|
          CustomerBonuses::ExpirationService.call(
            bonus,
            :expired_by_date
          )
        end
    end
  end
end
