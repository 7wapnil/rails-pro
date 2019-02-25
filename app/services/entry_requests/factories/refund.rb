# frozen_string_literal: true

module EntryRequests
  module Factories
    class Refund < ApplicationService
      def initialize(entry:, **attributes)
        @entry = entry
        @comment = attributes[:comment]
        @initiator = attributes[:initiator] || entry.customer
        @mode = attributes[:mode] || EntryRequest::CASHIER
      end

      def call
        create_entry_request!
        create_balance_requests!
        entry_request
      end

      private

      attr_reader :entry, :entry_request, :comment, :mode, :initiator

      def create_entry_request!
        @entry_request = EntryRequest.create!(
          amount: entry.amount,
          kind: EntryRequest::REFUND,
          customer: entry.customer,
          origin: entry,
          comment: comment,
          mode: mode,
          currency: entry.currency,
          initiator: initiator
        )
      end

      def create_balance_requests!
        balance_entry_amounts = entry
                                .balance_entries
                                .includes(:balance)
                                .pluck('balances.kind, balance_entries.amount')
                                .to_h
                                .symbolize_keys
        BalanceRequestBuilders::Refund.call(entry_request,
                                            balance_entry_amounts)
      end
    end
  end
end
