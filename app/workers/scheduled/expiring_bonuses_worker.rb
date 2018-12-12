module Scheduled
  class ExpiringBonusesWorker < ApplicationWorker
    sidekiq_options queue: 'expired_bonuses',
                    lock: :until_executed

    def perform
      CustomerBonus.all.each { |bonus| bonus.deactivate! if bonus.expired? }
    end
  end
end
