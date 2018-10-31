module Mts
  class ValidationMessagePublisherWorker < ApplicationWorker
    def perform(ids)
      @ids = ids
      raise NotImplementedError unless ids.length == 1

      publish_single_bet_validation(ids.first)
    end

    private

    def publish_single_bet_validation(id)
      bet = Bet.find(id)
      message = Mts::Messages::ValidationRequest.new([bet])
      response = Mts::SubmissionPublisher.publish!(message)
      raise if response == false

      bet.update(validation_ticket_id: message.ticket_id,
                 validation_ticket_sent_at: Time.zone.now)
    end
  end
end
