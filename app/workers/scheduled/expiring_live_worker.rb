module Scheduled
  class ExpiringLiveWorker < ApplicationWorker
    sidekiq_options unique_across_queues: true, queue: 'expired_live'

    def perform
      Bet.transaction do
        Bet.expired_live.update_all(status: :cancelled)
        Bet.expired_live.in_batches do |bet|
          WebSocket::Client.instance.emit(WebSocket::Signals::BET_CANCELLED,
                                          id: bet.id,
                                          customerId: bet.customer_id)
          message = {}
          Mts::MessagePublisher.publish!(message)
        end
      end
    end
  end
end
