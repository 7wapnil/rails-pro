# frozen_string_literal: true

module EntryRequests
  module Factories
    class RollbackBetRefund < ApplicationService
      delegate :refund_entry, to: :bet

      def initialize(bet_leg:)
        @bet_leg = bet_leg
        @bet = bet_leg.bet
      end

      def call
        EntryRequest.create!(entry_request_attributes)
      end

      private

      attr_reader :bet, :bet_leg

      def entry_request_attributes
        origin_attributes.merge(balance_attributes)
      end

      def origin_attributes
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          comment: comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def balance_attributes
        Bets::Clerk.call(bet: bet, origin: refund_entry, debit: true)
      end

      def comment
        "Rollback bet refund #{refund_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet_leg.event}."
      end
    end
  end
end
