# frozen_string_literal: true

module Bets
  class Cancel < ApplicationService
    VOIDED_ODD_VALUE = 1

    delegate :placement_entry, to: :bet

    def initialize(bet_leg:, bet:)
      @bet_leg = bet_leg
      @bet = bet
    end

    def call
      ActiveRecord::Base.transaction do
        bet_leg.cancelled_by_system!
        return unless resettle_bet?

        return_money
        return resettle if bet.combo_bets?

        bet.cancel_by_system!
      end
    end

    private

    attr_reader :bet_leg, :bet

    def resettle_bet?
      return true unless bet.combo_bets?

      bet.bet_legs
         .reject { |leg| leg.id == bet_leg.id }
         .all? { |leg| !leg.settlement_status.nil? && !leg.lost? }
    end

    def return_money
      requests = EntryRequests::Factories::BetCancellation.call(bet: bet)
      requests.each(&method(:proceed_entry_request))
    end

    def resettle
      bet.resettle!(settlement_status: resettlement_status)
      return unless bet.won?

      proceed_entry_request(place_entry_request)
      proceed_entry_request(win_entry_request)
    end

    def resettlement_status
      voided? ? Bet::VOIDED : Bet::WON
    end

    def proceed_entry_request(request)
      EntryRequests::ProcessingService.call(entry_request: request)
    end

    def place_entry_request
      ::EntryRequest.create!(
        kind: EntryKinds::BET,
        mode: EntryRequest::INTERNAL,
        amount: placement_entry.amount,
        real_money_amount: placement_entry.real_money_amount,
        bonus_amount: placement_entry.bonus_amount,
        comment: 'Resettlement',
        customer_id: bet.customer_id,
        currency_id: bet.currency_id,
        origin: bet
      )
    end

    def win_entry_request
      ::EntryRequests::Factories::WinPayout.call(
        origin: bet,
        kind: EntryKinds::WIN,
        mode: EntryRequest::INTERNAL,
        amount: bet.amount * won_odds_product,
        comment: "WIN for bet #{bet.id}"
      )
    end

    def voided?
      bet.bet_legs
         .reject { |leg| leg.id == bet_leg.id }
         .all? do |leg|
           leg.voided? || leg.cancelled_by_system?
         end
    end

    def won_odds_product
      bet.bet_legs
         .inject(1) { |product, leg| product * odd_value(leg) }
    end

    def odd_value(leg)
      return VOIDED_ODD_VALUE if leg.cancelled_by_system? ||
                                 leg.voided? ||
                                 leg.id == bet_leg.id

      leg.odd_value
    end
  end
end
