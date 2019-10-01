# frozen_string_literal: true

module Mts
  class ValidationResponseHandler < ApplicationService
    include JobLogger

    attr_reader :response

    def initialize(response)
      @response = Mts::Messages::ValidationResponse.new(response)
    end

    def call
      response.bets.each do |bet|
        next if cancelled_statuses.include?(bet.status)

        finish_external_validation_with_acceptance(bet) if response.accepted?
        finish_external_validation_with_rejection(bet) if response.rejected?
      end
    end

    private

    def cancelled_statuses
      ::StateMachines::BetStateMachine::CANCELLED_STATUSES_MASK
    end

    def finish_external_validation_with_acceptance(bet)
      bet.finish_external_validation_with_acceptance!
      WebSocket::Client.instance.trigger_bet_update(bet)
    end

    def finish_external_validation_with_rejection(bet)
      EntryRequests::BetRefundWorker.perform_async(refund_payload(bet))
      log_bet_failed_external_validation(bet)
    end

    def refund_payload(bet)
      {
        id: refund_entry_request(bet).id,
        message: response.rejection_message,
        code: response.rejection_key
      }
    end

    def refund_entry_request(bet)
      EntryRequests::Factories::Refund.call(
        entry: bet.entry,
        comment: 'Bet failed external validation.'
      )
    end

    def log_bet_failed_external_validation(bet)
      log_job_message(:info, message: 'Bet failed external validation.',
                             payload: response.rejection_json,
                             bet_id: bet.id)
    end
  end
end
