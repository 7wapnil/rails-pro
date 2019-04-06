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
          amount: -rollbacked_entry.amount,
          comment: comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet
        }
      end

      def rollbacked_entry
        @rollbacked_entry ||= bet.recent_win_entry
      end

      def comment
        "Rollback won amount #{rollbacked_entry.amount} #{bet.customer} " \
        "for #{bet.currency} on #{bet.event}."
      end
    end
  end
end
