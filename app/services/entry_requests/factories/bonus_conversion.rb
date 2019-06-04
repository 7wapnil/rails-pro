# frozen_string_literal: true

module EntryRequests
  module Factories
    class BonusConversion < ApplicationService
      delegate :wallet, to: :customer_bonus

      def initialize(customer_bonus:, amount:)
        @customer_bonus = customer_bonus
        @amount = amount
      end

      def call
        create_entry_request!
        create_balance_request!

        entry_request
      end

      attr_reader :customer_bonus, :amount, :entry_request

      private

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          amount: amount,
          mode: EntryRequest::INTERNAL,
          kind: EntryRequest::BONUS_CONVERSION,
          comment: comment,
          origin: customer_bonus,
          currency: wallet.currency,
          customer: wallet.customer
        }
      end

      def comment
        "Bonus conversion: #{amount} #{wallet.currency} " \
        "for #{wallet.customer}."
      end

      def create_balance_request!
        BalanceEntryRequest.create!(
          entry_request: entry_request,
          amount: amount,
          kind: Balance::REAL_MONEY
        )
      end
    end
  end
end
