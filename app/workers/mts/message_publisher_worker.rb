module Mts
  class MessagePublisherWorker < ApplicationWorker
    def perform(ids)
      raise NotImplementedError unless ids.length == 1

      bet = Bet.find(ids.first)
      message = Mts::Messages::ValidationRequest
                .new([bet])
      response = Mts::SubmissionPublisher.publish!(message)
      raise if response == false

      bet.update(validation_ticket_id: message.ticket_id)
    end
  end
end
