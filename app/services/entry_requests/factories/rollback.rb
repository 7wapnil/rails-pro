# frozen_string_literal: true

module EntryRequests
  module Factories
    class Rollback < ApplicationService
      def initialize(bet:)
        @bet = bet
      end

      def call
        create_entry_request!

        entry_request
      end

      private

      attr_reader :bet, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::SYSTEM,
          amount: -winning_entry.amount,
          comment: comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def winning_entry
        @winning_entry ||= bet.winning
      end

      def comment
        "Rollback won amount #{winning_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet.event}."
      end
    end
  end
end
