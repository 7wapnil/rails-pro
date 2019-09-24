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
      end

      def bet_cancel_request_attributes
        base_entry_request_attributes.merge(
          amount: placement_entry.amount.abs,
          comment: bet_cancel_comment,
          real_money_amount: -bet_entry.real_money_amount,
          bonus_amount: -bet_entry.bonus_amount
        )
      end

      def base_entry_request_attributes
        {
          kind: EntryKinds::SYSTEM_BET_CANCEL,
          mode: EntryRequest::INTERNAL,
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
      end

      def win_cancel_request_attributes
        base_entry_request_attributes.merge(
          amount: -winning_entry.amount,
          comment: win_cancel_comment,
          real_money_amount: -winning_entry.real_money_amount,
          bonus_amount: -winning_entry.bonus_amount
        )
      end

      def winning_entry
        @winning_entry ||= bet.winning
      end

      def bet_entry
        @bet_entry ||= bet.placement_entry
      end

      def win_cancel_comment
        "Cancel winnings - #{winning_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet.event}."
      end
    end
  end
end
