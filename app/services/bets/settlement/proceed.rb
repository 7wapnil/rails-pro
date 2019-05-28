# frozen_string_literal: true

module Bets
  module Settlement
    class Proceed < ApplicationService
      def initialize(bet:)
        @bet = bet
      end

      def call
        create_entry_request!

        return unless entry_request

        ::EntryRequests::BetSettlementWorker.perform_async(entry_request.id)
      end

      private

      attr_reader :bet, :entry_request

      def create_entry_request!
        return create_win_entry_request! if bet.won?

        create_refund_entry_request! if bet.void_factor
      end

      def create_win_entry_request!
        @entry_request = ::EntryRequests::Factories::WinPayout.call(
          origin: bet,
          kind: EntryRequest::WIN,
          mode: EntryRequest::INTERNAL,
          amount: bet.win_amount,
          comment: "WIN for bet #{bet.id}"
        )
      end

      def create_refund_entry_request!
        @entry_request = ::EntryRequests::Factories::WinPayout.call(
          origin: bet,
          kind: EntryRequest::REFUND,
          mode: EntryRequest::INTERNAL,
          amount: bet.refund_amount,
          comment: "REFUND for bet #{bet.id}"
        )
      end
    end
  end
end
