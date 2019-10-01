# frozen_string_literal: true

module EntryRequests
  class BetRefundService < ApplicationService
    include JobLogger

    def initialize(entry_request:, message:, code:)
      @entry_request = entry_request
      @bet = entry_request.origin
      @refund_message = message
      @refund_code = code
    end

    def call
      authorize_refund!
    rescue Bets::RequestFailedError, AASM::InvalidTransition => error
      log_job_error(error)
    end

    private

    attr_reader :entry_request, :bet, :refund_message, :refund_code

    def authorize_refund!
      ActiveRecord::Base.transaction do
        bet.lock!

        validate_entry_request!
        authorize_entry_request!

        bet.finish_external_validation_with_rejection!(
          refund_message,
          code: refund_code
        )

        notify_betslip_about_refund
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

    def notify_betslip_about_refund
      WebSocket::Client.instance.trigger_bet_update(bet.reload)
    end

    def log_job_error(error)
      log_job_message(:error, message: error.message,
                              bet_id: bet.id,
                              error_object: error)
    end
  end
end
