# frozen_string_literal: true

module Mts
  class ValidationResponseHandler < ApplicationService
    include JobLogger

    attr_reader :response, :bet

    def initialize(response_payload)
      @response = Mts::Messages::ValidationResponse.new(response_payload)
      @bet = response.bet
    end

    def call
      return if cancelled_statuses.include?(bet.status)
      return retry_external_validation if repeatable?

      finish_external_validation_with_acceptance if response.accepted?
      finish_external_validation_with_rejection if response.rejected?
    end

    private

    def cancelled_statuses
      ::StateMachines::BetStateMachine::CANCELLED_STATUSES_MASK
    end

    def retry_external_validation
      renew_outdated_bet_legs

      BetExternalValidation::Service.call(bet)
      WebSocket::Client.instance.trigger_bet_update(bet)

      log_bet_retry_external_validation
    end

    def repeatable?
      response.rejected? && bet.odds_change? && outdated_bet_legs.any?
    end

    def finish_external_validation_with_acceptance
      bet.finish_external_validation_with_acceptance!
      WebSocket::Client.instance.trigger_bet_update(bet)
    end

    def finish_external_validation_with_rejection
      EntryRequests::BetRefundWorker.perform_async(refund_entry_request.id,
                                                   response.rejection_key,
                                                   response.rejection_message,
                                                   response.rejection_details)
      log_bet_failed_external_validation
    end

    def renew_outdated_bet_legs
      outdated_bet_legs.each do |bet_leg|
        bet_leg.update(odd_value: bet_leg.odd.value)
      end
    end

    def outdated_bet_legs
      @outdated_bet_legs ||= bet.bet_legs
                                .joins(:odd)
                                .includes(:odd)
                                .where('bet_legs.odd_value != odds.value')
                                .load
    end

    def refund_entry_request
      EntryRequests::Factories::Refund.call(
        entry: bet.entry,
        comment: 'Bet failed external validation.'
      )
    end

    def log_bet_failed_external_validation
      log_job_message(:info, message: 'Bet failed external validation.',
                             payload: response.rejection_json,
                             bet_id: bet.id)
    end

    def log_bet_retry_external_validation
      log_job_message(:info, message: 'Bet retried external validation.',
                             payload: response.rejection_json,
                             bet_id: bet.id)
    end
  end
end
