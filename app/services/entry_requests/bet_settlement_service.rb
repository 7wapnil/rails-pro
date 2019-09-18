# frozen_string_literal: true

module EntryRequests
  class BetSettlementService < ApplicationService
    include JobLogger

    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      return handle_unexpected_bet! unless bet.settled?
      return failure if entry_request.failed?

      failure unless WalletEntry::AuthorizationService.call(entry_request)
    end

    private

    attr_reader :entry_request, :bet

    def handle_unexpected_bet!
      raise FailedEntryRequestError,
            'Entry request for settled bet is expected!'
    rescue FailedEntryRequestError => e
      log_job_message(:error,
                      message: e.message,
                      bet_id: bet.id,
                      error_object: e)

      entry_request.register_failure!(
        I18n.t('errors.messages.entry_request_for_settled_bet', bet_id: bet.id)
      )
    end

    def failure
      bet.send_to_manual_settlement!(entry_request.result['message'])
    end
  end
end
