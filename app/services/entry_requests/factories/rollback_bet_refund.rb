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
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          amount: -refund_entry.amount,
          comment: comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet,
          real_money_amount: -refund_entry.real_money_amount,
          bonus_amount: -refund_entry.bonus_amount
        }
      end

      def comment
        "Rollback bet refund #{refund_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet_leg.event}."
      end
    end
  end
end
