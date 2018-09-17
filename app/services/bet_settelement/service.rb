module BetSettelement
  class Service < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def handle
      unless @bet.settled? && @bet.result == true
        return handle_unexpected_bet
      end

      create_entry_request
      send_entry_request_for_wallet_authorization
    end

    private

    def handle_unexpected_bet; end

    def create_entry_request
      raise NotImplementedError
    end

    def send_entry_request_for_wallet_authorization
      raise NotImplementedError
    end

  end
end
