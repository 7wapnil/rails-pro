# frozen_string_literal: true

module EntryRequests
  class BetPlacementService < ApplicationService
    include JobLogger

    NOTIFICATION_ERROR_CODE = Bets::Notification::INTERNAL_VALIDATION_ERROR

    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      authorize_bet!
    rescue Bets::RegistrationError, RuntimeError => error
      bet_register_failure!(error)
      entry_request.register_failure!(error.message)
    rescue Bets::RequestFailedError => error
      bet_register_failure!(error)
      log_job_error(error)
    rescue AASM::InvalidTransition => error
      log_job_error(error)
    end

    private

    attr_reader :entry_request, :bet

    def authorize_bet!
      ActiveRecord::Base.transaction do
        bet.lock!
        bet.send_to_internal_validation!

        validate_bet!
        validate_entry_request!
        authorize_entry_request!

        bet.finish_internal_validation_successfully! do
          bet.send_to_external_validation!
        end
      end
    end

    # TODO: rebuild form to use native errors handler
    def validate_bet!
      validator.new(subject: bet).validate!
    end

    # TODO: rebuild form to use native errors handler
    def validate_entry_request!
      ::Bets::PlacementEntryRequestForm.new(subject: entry_request).validate!
    end

    def authorize_entry_request!
      WalletEntry::AuthorizationService.call(entry_request)
      return true if entry_request.succeeded?

      raise Bets::RegistrationError, entry_request.result_message
    end

    def bet_register_failure!(error)
      bet.register_failure!(error.message, code: NOTIFICATION_ERROR_CODE)
      notify_betslip_about_failure
    end

    def notify_betslip_about_failure
      WebSocket::Client.instance.trigger_bet_update(bet.reload)
    end

    def log_job_error(error)
      log_job_message(:error, message: error.message,
                              bet_id: bet.id,
                              error_object: error)
    end

    def validator
      return ::Bets::ComboBets::PlacementForm if bet.combo_bets?

      ::Bets::SingleBets::PlacementForm
    end
  end
end
