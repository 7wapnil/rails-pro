# frozen_string_literal: true

module EntryRequests
  class BetSettlementService < ApplicationService
    include JobLogger

    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      return handle_unexpected_bet! unless acceptable_bet?
      return failure if entry_request.failed?

      failure unless WalletEntry::AuthorizationService.call(entry_request)
    end

    private

    attr_reader :entry_request, :bet

    def acceptable_bet?
      bet.settled? || bet.voided?
    end

    def handle_unexpected_bet!
      log_job_message(:error,
                      message: 'Entry request for settled bet is expected!',
                      bet_id: bet.id)

      entry_request.register_failure!(
        I18n.t('errors.messages.entry_request_for_settled_bet', bet_id: bet.id)
      )
    end

    def failure
      bet.pending_manual_settlement!
    end
  end
end
