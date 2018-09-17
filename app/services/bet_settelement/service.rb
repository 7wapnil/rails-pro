module BetSettelement
  class Service < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def handle
      @bet.settled? ? handle_bet : handle_unexpected_bet
    end

    private

    def handle_unexpected_bet; end

    def handle_bet
      raise NotImplementedError
    end
  end
end
