module BetSettelement
  class Service < ApplicationService
    ENTRY_REQUEST_WIN_KIND = EntryRequest.kinds[:win]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def handle
      return handle_unexpected_bet unless @bet.settled? && @bet.result == true

      prepare_entry_request
      prepare_wallet_entries
    end

    private

    def handle_unexpected_bet; end

    # TODO: Fix Naming/MemoizedInstanceVariableName
    #
    # rubocop:disable Naming/MemoizedInstanceVariableName
    def prepare_entry_request
      @entry_request ||= EntryRequest.create!(
        amount: @bet.outcome_amount,
        currency: @bet.currency,
        kind: ENTRY_REQUEST_WIN_KIND,
        mode: ENTRY_REQUEST_MODE,
        # TODO: Figure out about initiator
        initiator: User.find_by_email('api@arcanebet.com'),
        comment: 'Automatic message',
        customer: @bet.customer,
        origin: @bet
      )
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName

    def prepare_wallet_entries
      raise NotImplementedError
    end
  end
end
