module Mts
  class ValidationResponseHandler < ApplicationService
    include JobLogger

    attr_reader :response

    def initialize(response)
      @response = Mts::Messages::ValidationResponse.new(response)
    end

    def call
      response.bets.each do |bet|
        bet.finish_external_validation_with_acceptance! if response.accepted?
        reject_bet!(bet) if response.rejected?

        WebSocket::Client.instance.trigger_bet_update(bet)
      end
    end

    private

    def reject_bet!(bet)
      refund = EntryRequests::Factories::Refund.call(
        entry: bet.entry,
        comment: 'Bet failed external validation.'
      )

      EntryRequests::RefundWorker.perform_async(refund.id)

      log_job_message(:info, message: 'Bet failed external validation.',
                             payload: response.rejection_json,
                             bet_id: bet.id)

      bet.finish_external_validation_with_rejection!(
        response.rejection_message,
        code: Bets::Notification::EXTERNAL_VALIDATION_ERROR
      )
    end
  end
end
