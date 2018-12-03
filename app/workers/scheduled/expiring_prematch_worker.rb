module Scheduled
  class ExpiringPrematchWorker < ApplicationWorker
    sidekiq_options queue: 'expired_prematch',
                    lock: :until_executed

    def perform
      Bet.transaction do
        Bet.expired_prematch.update_all(status: :cancelled)
        Bet.expired_prematch.in_batches do |bet|
          WebSocket::Client.instance.emit(WebSocket::Signals::BET_CANCELLED,
                                          id: bet.id,
                                          customerId: bet.customer_id)
          message = { bet: bet, body: 'message body...' }
          Mts::MessagePublisher.publish!(message)
        end
      end
    end
  end
end
