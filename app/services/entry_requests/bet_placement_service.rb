# frozen_string_literal: true

module EntryRequests
  class BetPlacementService < ApplicationService
    include JobLogger

    delegate :odd, :market, to: :bet

    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      bet.send_to_internal_validation!

      return notify_betslip_about_failure unless validate

      bet.finish_internal_validation_successfully! do
        bet.send_to_external_validation!
      end
    end

    private

    attr_reader :entry_request, :bet

    def validate
      validate_bet! && validate_entry_request!
    rescue Bets::PlacementError => error
      bet.register_failure!(error.message)
      entry_request.register_failure!(error.message)
      false
    rescue Bets::RequestFailedError => error
      bet.register_failure!(error.message)
      false
    end

    def validate_bet!
      ::Bets::PlacementForm.new(subject: bet).validate!
    end

    def validate_entry_request!
      return entry_request_failed! if entry_request.failed?
      return zero_amount! if entry_request.amount.zero?

      WalletEntry::AuthorizationService.call(entry_request)

      return true if entry_request.succeeded?

      raise Bets::PlacementError, entry_request.result_message
    end

    def entry_request_failed!
      message = I18n.t('errors.messages.entry_request_failed')
      log_job_message(:error, message: message, bet_id: bet.id)
      raise Bets::RequestFailedError, message
    end

    def zero_amount!
      raise Bets::PlacementError,
            I18n.t('errors.messages.real_money_blank_amount')
    end

    def notify_betslip_about_failure
      ::Bets::NotificationWorker.perform_async(bet.id)
    end
  end
end
