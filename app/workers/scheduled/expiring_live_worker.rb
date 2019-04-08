module Scheduled
  class ExpiringLiveWorker < ApplicationWorker
    sidekiq_options queue: 'expired_live',
                    lock: :until_executed

    def perform
      Bet.transaction do
        Bet.expired_live.in_batches do |bet|
          Mts::Publishers::BetCancellation.publish!(bet: bet)
        end
      end
    end
  end
end
