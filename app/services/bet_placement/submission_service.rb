module BetPlacement
  class SubmissionService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest.kinds[:bet]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def call
      @entry = WalletEntry::AuthorizationService.call(entry_request)
      @bet.failure!(@entry_request.result_message) if @entry_request.failed?
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
  end
end
