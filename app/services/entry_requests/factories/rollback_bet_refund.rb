# frozen_string_literal: true

module EntryRequests
  module Factories
    class RollbackBetRefund < ApplicationService
      delegate :refund_entry, to: :bet

      def initialize(bet:)
        @bet = bet
      end

      def call
        EntryRequest.create!(entry_request_attributes)
      end

      private

      attr_reader :bet

      def entry_request_attributes
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          amount: -refund_entry.amount,
          comment: comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def comment
        "Rollback bet refund #{refund_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet.event}."
      end
    end
  end
end
