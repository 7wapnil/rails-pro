# frozen_string_literal: true

module EntryRequests
  class BetSettlementService < ApplicationService
    include JobLogger

    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      return if entry_request.failed?
      return handle_unexpected_bet! unless bet.settled?

      entry = ::WalletEntry::AuthorizationService.call(entry_request)

      return unless entry

      ::CustomerBonuses::BetSettlementService.call(bet)
    end

    delegate :customer_bonus, to: :bet

    private

    attr_reader :entry_request, :bet

    def handle_unexpected_bet!
      log_job_message(:error,
                      message: 'Entry request for settled bet is expected!',
                      bet_id: bet.id)

      entry_request.register_failure!(
        I18n.t('errors.messages.entry_request_for_settled_bet', bet_id: bet.id)
      )
    end
  end
end
