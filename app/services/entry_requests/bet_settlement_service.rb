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

      ::WalletEntry::AuthorizationService.call(entry_request)
      
      return unless bet.customer_bonus

      bet.customer_bonus.with_lock do
        recalculate_bonus_rollover
        complete_bonus if bet.customer_bonus&.rollover_balance&.negative?
      end
    end

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

    def recalculate_bonus_rollover
      ::CustomerBonuses::RolloverCalculationService.call(
        customer_bonus: bet.customer_bonus
      )
    end

    def complete_bonus
      ::CustomerBonuses::Complete.call(customer_bonus: bet.customer_bonus)
    end
  end
end
