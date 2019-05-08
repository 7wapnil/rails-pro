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
      bet.update(
        message: I18n.t('errors.messages.mts.failed_external_validation')
      )
      log_job_message(:info, message: message, bet_id: bet.id)

      bet.finish_external_validation_with_rejection!
    end

    def message
      @message ||= @response.message.dig(:result, :reason, :message)
    end
  end
end
