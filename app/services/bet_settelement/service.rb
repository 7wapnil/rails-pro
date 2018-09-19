module BetSettelement
  class Service < ApplicationService
    ENTRY_REQUEST_WIN_KIND = EntryRequest.kinds[:win]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def call
      return handle_unexpected_bet unless @bet.settled? && @bet.result == true

      entry_requests
      apply_requests_to_wallets
    end

    private

    def handle_unexpected_bet; end

    def entry_requests
      @entry_requests ||= [win_entry_request].compact
    end

    def win_entry_request
      @win_entry_request ||= EntryRequest.create!(
        amount: @bet.win_amount,
        currency: @bet.currency,
        kind: ENTRY_REQUEST_WIN_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: @bet.customer,
        customer: @bet.customer,
        origin: @bet
      )
    end

    def apply_requests_to_wallets
      @entry_requests.each do |entry_request|
        WalletEntry::AuthorizationService.call(entry_request)
      end
    end
  end
end
