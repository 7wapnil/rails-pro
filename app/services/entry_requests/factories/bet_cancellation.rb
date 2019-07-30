# frozen_string_literal: true

module EntryRequests
  module Factories
    class BetCancellation < ApplicationService
      delegate :placement_entry, to: :bet

      def initialize(bet:)
        @bet = bet
      end

      def call
        create_bet_cancel_request!
        create_win_cancel_request! if bet.won?

        [bet_cancel_request, win_cancel_request].compact
      end

      private

      attr_reader :bet, :bet_cancel_request, :win_cancel_request

      def create_bet_cancel_request!
        @bet_cancel_request = EntryRequest
                              .create!(bet_cancel_request_attributes)

        create_balance_entry_requests_for!(
          original_entry: bet_entry,
          entry_request: bet_cancel_request
        )
      end

      def bet_cancel_request_attributes
        {
          kind: EntryKinds::SYSTEM_BET_CANCEL,
          mode: EntryRequest::INTERNAL,
          amount: placement_entry.amount.abs,
          comment: bet_cancel_comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def bet_cancel_comment
        "Cancel bet - #{placement_entry.amount.abs} #{bet.currency} " \
        "for #{bet.customer} on #{bet.event}."
      end

      def create_win_cancel_request!
        @win_cancel_request = EntryRequest
                              .create!(win_cancel_request_attributes)

        create_balance_entry_requests_for!(
          original_entry: winning_entry,
          entry_request: win_cancel_request
        )
      end

      def win_cancel_request_attributes
        {
          kind: EntryKinds::SYSTEM_BET_CANCEL,
          mode: EntryRequest::INTERNAL,
          amount: -winning_entry.amount,
          comment: win_cancel_comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def winning_entry
        @winning_entry ||= bet.winning
      end

      def bet_entry
        @bet_entry ||= bet.entry
      end

      def win_cancel_comment
        "Cancel winnings - #{winning_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet.event}."
      end

      def create_balance_entry_requests_for!(original_entry:, entry_request:)
        balance_entries = original_entry.balance_entries.includes(:balance)

        balance_entry_amounts = balance_entries.map do |balance_entry|
          [balance_entry.balance.kind, balance_entry.amount.abs]
        end

        balance_entry_amounts = balance_entry_amounts.to_h.symbolize_keys!

        BalanceRequestBuilders::Refund.call(
          entry_request,
          balance_entry_amounts
        )
      end
    end
  end
end
