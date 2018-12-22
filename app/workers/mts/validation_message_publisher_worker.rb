module Mts
  class ValidationMessagePublisherWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(ids)
      super()

      @ids = ids

      unless ids.length == 1
        log_job_failure NotImplementedError
        raise NotImplementedError
      end

      publish_single_bet_validation(ids.first)
    end

    private

    def publish_single_bet_validation(id)
      bet = Bet.find(id)
      message = Mts::Messages::ValidationRequest.new([bet])
      response = Mts::MessagePublisher.publish!(message)
      raise if response == false

      bet.update(validation_ticket_id: message.ticket_id,
                 validation_ticket_sent_at: Time.zone.now)
    end
  end
end
