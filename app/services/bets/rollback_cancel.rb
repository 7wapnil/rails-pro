# frozen_string_literal: true

module Bets
  class RollbackCancel < ApplicationService
    def initialize(bet_leg:, bet:)
      @bet_leg = bet_leg
      @bet = bet
    end

    def call
      ActiveRecord::Base.transaction do
        rollback_bet_leg_status
        return unless resettle_bet?

        rollback_money

        return resettle_bet if bet.combo_bets?
        return settle_bet if bet.settlement_status.present?

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

    def resettle_bet?
      return true unless bet.combo_bets?
      return true if bet_leg.lost? && !(bet.settled? && bet.lost?)

      bet.bet_legs
         .reject { |leg| leg.id == bet_leg.id }
         .all? { |leg| !leg.settlement_status.nil? && !leg.lost? }
    end

    def rollback_bet_leg_status
      bet_leg.update(status: nil)
    end

    def proceed_entry_request(request)
      EntryRequests::ProcessingService.call(entry_request: request)
    end

    def settle_bet
      bet.rollback_system_cancellation_with_settlement!(
        settlement_status: bet.settlement_status
      )
    end

    def resettle_bet
      bet.resettle!(settlement_status: resettlement_status)
      return unless bet.won?

      proceed_entry_request(win_entry_request)
    end

    def win_entry_request
      ::EntryRequests::Factories::WinPayout.call(
        origin: bet,
        kind: EntryRequest::WIN,
        mode: EntryRequest::INTERNAL,
        amount: bet.amount * won_odds_product,
        comment: "WIN for bet #{bet.id}"
      )
    end

    def resettlement_status
      return Bet::LOST if bet_leg.lost?

      voided? ? Bet::VOIDED : Bet::WON
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

    def won_odds_product
      bet.bet_legs
         .inject(1) { |product, leg| product * odd_value(leg) }
    end

    def odd_value(leg)
      return Bets::Cancel::VOIDED_ODD_VALUE if leg.voided?
      return Bets::Cancel::VOIDED_ODD_VALUE if leg.cancelled_by_system? &&
                                               leg.id != bet_leg.id

      leg.odd_value
    end
  end
end
