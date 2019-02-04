module EntryRequests
  module Factories
    class BetSettlement < ApplicationService
      def initialize(bet:)
        @bet = bet
        @entry_requests = []
      end

      def call
        create_entry_requests!

        entry_requests
      end

      private

      attr_reader :bet, :entry_requests

      def create_entry_requests!
        create_win_entry_request! if bet.won?
        create_refund_entry_request! if bet.void_factor
      end

      def create_win_entry_request!
        @entry_requests << Common.call(
          origin: bet,
          kind: EntryRequest::WIN,
          mode: EntryRequest::SYSTEM,
          amount: bet.win_amount
        )
      end

      def create_refund_entry_request!
        @entry_requests << Common.call(
          origin: bet,
          kind: EntryRequest::REFUND,
          mode: EntryRequest::SYSTEM,
          amount: bet.refund_amount
        )
      end
    end
  end
end
