module BetSettelement
  class Service < ApplicationService
    ENTRY_REQUEST_WIN_KIND = EntryRequest.kinds[:win]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def handle
      return handle_unexpected_bet unless @bet.settled? && @bet.result == true

      generate_requests
      apply_requests
    end

    private

    def handle_unexpected_bet; end

    def generate_requests
      entry_request
    end

    def entry_request
      @entry_request ||= EntryRequest.create!(
        amount: @bet.outcome_amount,
        currency: @bet.currency,
        kind: ENTRY_REQUEST_WIN_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: @bet.customer,
        customer: @bet.customer,
        origin: @bet
      )
    end

    def prepare_wallet_entries
      raise NotImplementedError
    end
  end
end
