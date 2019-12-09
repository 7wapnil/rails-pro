# frozen_string_literal: true

module BetPlacement
  class BettingLimitsValidationService < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def call
      global_limit&.validate!(bet)

      bet_legs.each do |bet_leg|
        limit_by_title(bet_leg)&.validate!(bet)
      end
    end

    private

    attr_reader :bet

    delegate :customer, to: :bet

    def bet_legs
      bet.bet_legs.includes(:title)
    end

    def limit_by_title(bet_leg)
      BettingLimit.find_by(customer: customer, title: bet_leg.title)
    end

    def global_limit
      BettingLimit.find_by(customer: customer, title: nil)
    end
  end
end
