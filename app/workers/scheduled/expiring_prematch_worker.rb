module Scheduled
  class ExpiringPrematchWorker < ApplicationWorker
    sidekiq_options unique_across_queues: true, queue: 'expired_prematch'

    def perform
      Bet.transaction do
        Bet.expired_prematch.in_batches do |bet|
          # TODO: handle bet
          # TODO: submit expiration message
        end
      end
    end
  end
end
