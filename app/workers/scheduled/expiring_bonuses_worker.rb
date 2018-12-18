module Scheduled
  class ExpiringBonusesWorker < ApplicationWorker
    sidekiq_options queue: 'expired_bonuses',
                    lock: :until_executed

    def perform
      # TODO: pass correct deactivation service
      service = 'ExpiredBonus'
      CustomerBonus.all.each { |bonus| bonus.close!(service) if bonus.expired? }
    end
  end
end
