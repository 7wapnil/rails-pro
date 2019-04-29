# frozen_string_literal: true

module EntryRequests
  module Factories
    class Confiscation < ApplicationService
      delegate :currency, :customer, to: :wallet

      def initialize(wallet:, amount:)
        @wallet = wallet
        @amount = amount
      end

      def call
        create_entry_request!
        create_balance_request!

        entry_request
      end

      private

      attr_reader :wallet, :amount, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          kind: EntryKinds::CONFISCATION,
          mode: EntryRequest::SYSTEM,
          amount: -amount,
          comment: comment,
          customer: customer,
          currency: currency,
          origin: wallet
        }
      end

      def comment
        "Confiscation of #{amount} #{currency} from #{customer} bonus balance."
      end

      def create_balance_request!
        BalanceEntryRequest.create!(
          entry_request: entry_request,
          amount: -amount,
          kind: Balance::BONUS
        )
      end
    end
  end
end
