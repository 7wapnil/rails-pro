module Scheduled
  class ExpiringPrematchWorker < ApplicationWorker
    sidekiq_options queue: 'expired_prematch',
                    lock: :until_executed

    def perform
      Bet.transaction do
        Bet.expired_prematch.in_batches do |bet|
          Mts::Publishers::BetCancellation.publish!(bet: bet)
        end
      end
    end
  end
end
