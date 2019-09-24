# frozen_string_literal: true

module EntryRequests
  module Factories
    class Refund < ApplicationService
      def initialize(entry:, **attributes)
        @entry = entry
        @comment = attributes[:comment]
        @initiator = attributes[:initiator] || entry.customer
        @mode = attributes.fetch(:mode) { populate_mode }
      end

      def call
        create_entry_request!
        entry_request
      end

      private

      attr_reader :entry, :entry_request, :comment, :mode, :initiator

      def populate_mode
        entry.entry_request&.mode || EntryRequest::CASHIER
      end

      def create_entry_request!
        @entry_request = EntryRequest.create!(
          amount: entry.amount,
          kind: EntryRequest::REFUND,
          customer: entry.customer,
          origin: entry.origin,
          comment: comment,
          mode: mode,
          currency: entry.currency,
          initiator: initiator,
          real_money_amount: entry.real_money_amount.abs,
          bonus_amount: entry.bonus_amount.abs
        )
      end
    end
  end
end
