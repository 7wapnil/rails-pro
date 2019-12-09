# frozen_string_literal: true

module EntryRequests
  module Factories
    class RollbackBetCancellation < ApplicationService
      delegate :placement_rollback_entry,
               :winning_rollback_entry,
               :winning_resettle_entry,
               to: :bet

      def initialize(bet:, bet_leg:)
        @bet = bet
        @bet_leg = bet_leg
      end

      def call
        create_bet_rollback_request!
        create_win_rollback_request! if winning_rollback_entry
        create_resettle_rollback_request! if winning_resettle_entry

        entry_requests.compact
      end

      private

      attr_reader :bet, :bet_leg, :bet_rollback_request, :win_rollback_request,
                  :resettle_rollback_request

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
        "#{bet.currency} for #{bet.customer} on #{bet_leg.event}."
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
          real_money_amount: winning_rollback_entry.real_money_amount.abs,
          bonus_amount: winning_rollback_entry.bonus_amount.abs
        }
      end

      def win_rollback_comment
        "Rollback winning cancellation - #{winning_rollback_entry.amount} " \
        "#{bet.currency} for #{bet.customer} on #{bet_leg.event}."
      end

      def create_resettle_rollback_request!
        @resettle_rollback_request = EntryRequest
                                     .create!(resettle_rollback_request_attrs)
      end

      def resettle_rollback_request_attrs
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          amount: -winning_resettle_entry.amount.abs,
          comment: resettle_rollback_comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet,
          real_money_amount: -winning_resettle_entry.real_money_amount.abs,
          bonus_amount: -winning_resettle_entry.bonus_amount.abs
        }
      end

      def resettle_rollback_comment
        "Rollback winning resettlement - #{winning_resettle_entry.amount} " \
        "#{bet.currency} for #{bet.customer} on #{bet_leg.event}."
      end

      def entry_requests
        [
          bet_rollback_request,
          win_rollback_request,
          resettle_rollback_request
        ]
      end
    end
  end
end
