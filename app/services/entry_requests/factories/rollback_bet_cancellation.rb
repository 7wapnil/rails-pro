# frozen_string_literal: true

module EntryRequests
  module Factories
    class RollbackBetCancellation < ApplicationService
      delegate :placement_rollback_entry, :placement_entry,
               :winning_rollback_entry, :winning,
               to: :bet

      def initialize(bet:, bet_leg:)
        @bet = bet
        @bet_leg = bet_leg
      end

      def call
        create_bet_rollback_request! if place_cancelled?
        create_win_rollback_request! if winning_rollback?
        create_resettle_rollback_request! if winning_cancel?

        entry_requests.compact
      end

      private

      attr_reader :bet, :bet_leg, :bet_rollback_request, :win_rollback_request,
                  :resettle_rollback_request

      def create_bet_rollback_request!
        @bet_rollback_request = EntryRequest
                                .create!(bet_rollback_request_attrs)
      end

      def place_cancelled?
        return false unless placement_entry && placement_rollback_entry

        placement_entry.id < placement_rollback_entry.id
      end

      def bet_rollback_request_attrs
        {
          **base_request_attrs,
          **money_transitions(placement_rollback_entry, true),
          kind: EntryKinds::ROLLBACK,
          comment: bet_rollback_comment
        }
      end

      def base_request_attrs
        {
          mode: EntryRequest::INTERNAL,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def money_transitions(entry, debit)
        Bets::Clerk.call(bet: bet, origin: entry, debit: debit)
      end

      def bet_rollback_comment
        "Rollback bet cancellation - #{placement_rollback_entry.amount.abs} " \
        "#{bet.currency} for #{bet.customer} on #{bet_leg.event}."
      end

      def create_win_rollback_request!
        @win_rollback_request = EntryRequest
                                .create!(win_rollback_request_attrs)
      end

      def winning_rollback?
        return false if bet.combo_bets?
        return false unless winning && winning_rollback_entry

        winning.id < winning_rollback_entry.id
      end

      def win_rollback_request_attrs
        {
          **base_request_attrs,
          **money_transitions(winning_rollback_entry, false),
          kind: EntryKinds::ROLLBACK,
          comment: win_rollback_comment
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

      def winning_cancel?
        return false unless bet.combo_bets? && winning
        return true unless winning_rollback_entry

        winning.id > winning_rollback_entry.id
      end

      def resettle_rollback_request_attrs
        {
          **base_request_attrs,
          **money_transitions(winning, true),
          kind: EntryKinds::SYSTEM_BET_CANCEL,
          comment: resettle_rollback_comment
        }
      end

      def resettle_rollback_comment
        "Rollback winning resettlement - #{winning.amount} " \
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
