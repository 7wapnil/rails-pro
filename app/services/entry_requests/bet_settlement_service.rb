module EntryRequests
  class BetSettlementService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      return handle_unexpected_bet! unless bet.settled?

      ::WalletEntry::AuthorizationService.call(entry_request)
    end

    private

    attr_reader :entry_request, :bet

    def handle_unexpected_bet!
      raise(
        ArgumentError,
        'Entry request for settled bet is expected!'
      )
    end
  end
end
