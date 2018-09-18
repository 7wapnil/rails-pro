module BetPlacement
  class Service < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest.kinds[:bet]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def call
      @entry = WalletEntry::AuthorizationService.call(entry_request)
      update_bet_from_request!
      @bet
    end

    private

    def entry_request
      @entry_request ||= EntryRequest.create!(
        amount: @bet.amount,
        currency: @bet.currency,
        kind: ENTRY_REQUEST_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: @bet.customer,
        customer: @bet.customer,
        origin: @bet
      )
    end

    def update_bet_from_request!
      @bet.update_attributes!(
        status: @entry_request.status,
        message: @entry_request.result_message
      )
    end
  end
end
