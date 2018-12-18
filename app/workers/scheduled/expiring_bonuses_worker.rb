module Scheduled
  class ExpiringBonusesWorker < ApplicationWorker
    sidekiq_options queue: 'expired_bonuses',
                    lock: :until_executed

    def perform
      super()

      CustomerBonus.all.each do |bonus|
        skip unless bonus.expired?

        CustomerBonuses::ExpirationService.call(
          bonus,
          :expired_by_date
        )
      end
    end
  end
end
