module Mts
  class ValidationMessagePublisherWorker < ApplicationWorker
    def perform(ids)
      raise NotImplementedError unless ids.length == 1

      bet = Bet.find(ids.first)
      message = Mts::Messages::ValidationRequest
                .new([bet])
      response = Mts::SubmissionPublisher.publish!(message)
      raise if response == false

      bet.update(validation_ticket_id: message.ticket_id,
                 validation_ticket_sent_at: Time.zone.now)
    end
  end
end
