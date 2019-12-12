# frozen_string_literal: true

module EntryRequests
  class BetCancellationService < ApplicationService
    include JobLogger

    def initialize(entry_request:, status_code:)
      @entry_request = entry_request
      @bet = entry_request.origin
      @status_code = status_code
    end

    def call
      authorize_refund!
    rescue Bets::RequestFailedError, AASM::InvalidTransition => error
      log_job_error(error)
    end

    private

    attr_reader :entry_request, :bet, :status_code

    def authorize_refund!
      ActiveRecord::Base.transaction do
        bet.lock!

        validate_entry_request!
        authorize_entry_request!

        update_bet_status!
        notify_betslip
      end
    end

    def validate_entry_request!
      return unless entry_request.failed? || entry_request.entry.present?

      raise Bets::RequestFailedError, 'Already authorized entry request'
    end

    def authorize_entry_request!
      WalletEntry::AuthorizationService.call(entry_request)
      return if entry_request.succeeded?

      raise Bets::RequestFailedError, entry_request.result_message
    end

    def update_bet_status!
      return bet.cancel! if successful_status_code?

      bet.finish_external_cancellation_with_rejection!(
        I18n.t("errors.messages.mts.#{error_code}"),
        code: Bets::Notification::MTS_CANCELLATION_ERROR
      )
      log_unsuccessful_bet_cancel_error
    end

    def notify_betslip
      WebSocket::Client.instance.trigger_bet_update(bet)
    end

    def successful_status_code?
      status_code == Mts::Codes::SUCCESSFUL_CODE
    end

    def error_code
      Mts::Codes::CANCELLATION_ERROR_CODES[status_code]
    end

    def log_unsuccessful_bet_cancel_error
      raise ::Bets::UnsuccessfulBetCancelError,
            I18n.t("errors.messages.mts.#{error_code}")
    rescue ::Bets::UnsuccessfulBetCancelError => e
      log_job_message(:error, message: e.message,
                              bet_id: bet.id,
                              error_object: e)
    end

    def log_job_error(error)
      log_job_message(:error, message: error.message,
                              bet_id: bet.id,
                              error_object: error)
    end
  end
end
