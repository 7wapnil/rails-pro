# frozen_string_literal: true

module Bets
  class Cancel < ApplicationService
    VOIDED_ODD_VALUE = 1

    delegate :placement_entry, to: :bet

    def initialize(bet_leg:, bet:)
      @bet_leg = bet.bet_legs.find { |leg| leg.id == bet_leg.id }
      @bet = bet
    end

    def call
      ActiveRecord::Base.transaction do
        lock_important_entities!

        bet_leg.cancelled_by_system!
        return unless resettle_bet?

        return_money
        return resettle if bet.combo_bets?

        bet.cancel_by_system!
        rollback_bonus_rollover!
      end
    end

    private

    attr_reader :bet_leg, :bet

    def lock_important_entities!
      bet.lock!
      bet_leg.lock!
      bet.customer_bonus&.lock!
    end

    def resettle_bet?
      return true unless bet.combo_bets?

      bet.bet_legs.all?(&method(:not_pending_or_lost_bet_leg?))
    end

    def return_money
      requests = EntryRequests::Factories::BetCancellation.call(bet: bet)
      requests.each(&method(:proceed_entry_request))
    end

    def resettle
      bet.resettle!(settlement_status: resettlement_status)
      settle_customer_bonus! unless bet.voided?
      return unless bet.won?

      proceed_entry_request(place_entry_request)
      proceed_entry_request(win_entry_request)
    end

    def settle_customer_bonus!
      CustomerBonuses::BetSettlementService.call(bet)
    end

    def rollback_bonus_rollover!
      CustomerBonuses::RollbackBonusRolloverService.call(bet: bet)
    end

    def resettlement_status
      voided? ? Bet::VOIDED : Bet::WON
    end

    def proceed_entry_request(request)
      EntryRequests::ProcessingService.call(entry_request: request)
    end

    def place_entry_request
      ::EntryRequest.create!(
        **replace_money_transitions,
        kind: EntryKinds::BET,
        mode: EntryRequest::INTERNAL,
        comment: 'Resettlement',
        customer_id: bet.customer_id,
        currency_id: bet.currency_id,
        origin: bet
      )
    end

    def replace_money_transitions
      Bets::Clerk.call(bet: bet, origin: placement_entry, debit: true)
    end

    def win_entry_request
      ::EntryRequests::Factories::WinPayout.call(
        origin: bet,
        kind: EntryKinds::WIN,
        mode: EntryRequest::INTERNAL,
        amount: bet.amount * bet.odd_value,
        comment: "WIN for bet #{bet.id}"
      )
    end

    def not_pending_or_lost_bet_leg?(leg)
      return true if leg.cancelled_by_system?

      leg.settlement_status.present? && !leg.lost? && !leg.unresolved?
    end

    def voided?
      bet.bet_legs.all? { |leg| leg.voided? || leg.cancelled_by_system? }
    end
  end
end
