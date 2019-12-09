# frozen_string_literal: true

module Bets
  class RollbackCancel < ApplicationService
    def initialize(bet_leg:, bet:)
      @bet_leg = bet_leg
      @bet = bet
    end

    def call
      ActiveRecord::Base.transaction do
        rollback_money
        rollback_bet_leg_status

        return settle_bet if settlement_status

        bet.rollback_system_cancellation_with_acceptance!
      end
    end

    private

    attr_reader :bet_leg, :bet

    def rollback_money
      requests = EntryRequests::Factories::RollbackBetCancellation
                 .call(bet: bet, bet_leg: bet_leg)
      requests.each { |request| proceed_entry_request(request) }
    end

    def rollback_bet_leg_status
      bet_leg.update(status: nil)
    end

    def proceed_entry_request(request)
      EntryRequests::ProcessingService.call(entry_request: request)
    end

    def settle_bet
      bet.rollback_system_cancellation_with_settlement!(
        settlement_status: settlement_status
      )
    end

    def settlement_status
      return bet.settlement_status unless bet.combo_bets?
      return if any_unsettled_bet_legs?
      return Bet::VOIDED if voided?

      Bet::WON
    end

    def any_unsettled_bet_legs?
      bet.bet_legs
         .any? do |leg|
           leg.settlement_status.nil? && !leg.cancelled_by_system?
         end
    end

    def voided?
      bet.bet_legs
         .all? do |leg|
           next true if leg.voided?
           next false if leg.id == bet_leg.id

           leg.cancelled_by_system?
         end
    end
  end
end
