module Mts
  class ValidationMessagePublisherWorker < ApplicationWorker
    def perform(ids)
      @ids = ids

      unless ids.length == 1
        log_job_failure NotImplementedError
        raise NotImplementedError
      end

      publish_single_bet_validation(ids.first)
    end

    private

    def publish_single_bet_validation(id)
      response = Publishers::BetValidation.publish!(bet: Bet.find_by(id: id))
      raise unless response
    end
  end
end
