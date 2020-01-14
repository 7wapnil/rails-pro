# frozen_string_literal: true

module Betting
  class PlaceResolver < ApplicationService
    def initialize(bets_payload:, impersonated_by:, customer:, combo_bets:)
      @bets_payload = bets_payload
      @impersonated_by = impersonated_by
      @customer = customer
      @combo_bets = combo_bets
    end

    def call
      return place_bet(bets_payload) if combo_bets?

      bets_payload.map { |payload| place_bet(payload) }
    end

    private

    attr_reader :bets_payload, :impersonated_by, :customer, :combo_bets

    alias_method :combo_bets?, :combo_bets

    def place_bet(bet_payload)
      bet = ::Bets::Place.call(
        payload: bet_payload,
        impersonated_by: impersonated_by,
        customer: customer,
        combo_bets: combo_bets
      ).decorate

      OpenStruct.new(success: true, bet: bet)
    rescue Bets::PlacementError => error
      OpenStruct.new(message: I18n.t('bets.notifications.placement_error'),
                     success: false,
                     bet: error.bet&.decorate,
                     odd_id: error.odd_id)
    end
  end
end
