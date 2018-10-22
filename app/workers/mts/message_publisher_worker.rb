module Mts
  class MessagePublisherWorker < ApplicationWorker
    def perform(message)
      response = Mts::SubmissionPublisher.publish!(message)
      raise if response == false

      update(validation_ticket_id: message.ticket_id)
    end
  end
end
