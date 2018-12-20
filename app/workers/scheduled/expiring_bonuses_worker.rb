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
          service = BonusDeactivation::Expired
          reason = :expired_by_date
          bonus.close!(service, reason: reason)
        end
    end
  end
end
