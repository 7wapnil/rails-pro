# frozen_string_literal: true

module EntryRequests
  module Factories
    class RollbackBetCancellation < ApplicationService
      delegate :placement_rollback_entry, :winning_rollback_entry, to: :bet

      def initialize(bet:)
        @bet = bet
      end

      def call
        create_bet_rollback_request!
        create_win_rollback_request! if bet.won?

        [bet_rollback_request, win_rollback_request].compact
      end

      private

      attr_reader :bet, :bet_rollback_request, :win_rollback_request

      def create_bet_rollback_request!
        @bet_rollback_request = EntryRequest
                                .create!(bet_rollback_request_attrs)
      end

      def bet_rollback_request_attrs
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          amount: -placement_rollback_entry.amount,
          comment: bet_rollback_comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet,
          real_money_amount: -placement_rollback_entry.real_money_amount,
          bonus_amount: -placement_rollback_entry.bonus_amount
        }
      end

      def bet_rollback_comment
        "Rollback bet cancellation - #{placement_rollback_entry.amount.abs} " \
        "#{bet.currency} for #{bet.customer} on #{bet.event}."
      end

      def create_win_rollback_request!
        @win_rollback_request = EntryRequest
                                .create!(win_rollback_request_attrs)
      end

      def win_rollback_request_attrs
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          amount: winning_rollback_entry.amount.abs,
          comment: win_rollback_comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet,
          real_money_amount: winning_rollback_entry.real_money_amount,
          bonus_amount: winning_rollback_entry.bonus_amount
        }
      end

      def win_rollback_comment
        "Rollback winning cancellation - #{winning_rollback_entry.amount} " \
        "#{bet.currency} for #{bet.customer} on #{bet.event}."
      end
    end
  end
end
