module BetPlacement
  class SubmissionService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest.kinds[:bet]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def call
      @bet.send_to_internal_validation!
      @entry = WalletEntry::AuthorizationService.call(entry_request)
      if @entry_request.failed?
        @bet.register_failure!(@entry_request.result_message)
        return @bet
      end
      @bet.finish_internal_validation_successfully!
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
