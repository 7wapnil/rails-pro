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
      update_customer_bonus
    end

    private

    attr_reader :entry_request, :bet

    def update_customer_bonus
      bonus = bet.customer.customer_bonus
      return unless bonus

      return if bet.void_factor

      balance = bonus.rollover_initial_value
      balance -= bonus.affecting_bets.map(&:amount).compact.sum
      bonus.update!(rollover_balance: balance)
    end

    def handle_unexpected_bet!
      message = I18n.t('errors.messages.entry_request_for_settled_bet',
                       bet_id: bet.id)

      log_job_failure(message)
      entry_request.register_failure!(message)
    end
  end
end
