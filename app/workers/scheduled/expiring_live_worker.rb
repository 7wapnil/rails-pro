module Scheduled
  class ExpiringLiveWorker < ApplicationWorker
    sidekiq_options unique_across_queues: true, queue: 'expired_live'

    def perform
      Bet.transaction do
        Bet.expired_live.in_batches do |bet|
          # TODO: handle bet
          # TODO: submit expiration message
        end
      end
    end
  end
end
