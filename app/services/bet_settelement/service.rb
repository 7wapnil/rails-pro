module BetSettelement
  class Service < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def handle
      raise NotImplementedError
    end
  end
end
