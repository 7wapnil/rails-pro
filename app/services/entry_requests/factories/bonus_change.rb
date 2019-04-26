# frozen_string_literal: true

module EntryRequests
  module Factories
    class BonusChange < ApplicationService
      def initialize(wallet:, amount:, initiator:)
        @wallet = wallet
        @amount = amount
        @initiator = initiator
      end

      def call
        create_entry_request!
        create_balance_request!

        entry_request
      end

      private

      attr_reader :wallet, :amount, :initiator, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          status: EntryRequest::INITIAL,
          amount: amount,
          mode: EntryRequest::INTERNAL,
          kind: EntryRequest::BONUS_CHANGE,
          initiator: initiator,
          comment: comment,
          origin: wallet,
          currency: wallet.currency,
          customer: wallet.customer
        }
      end

      def comment
        "Bonus transaction: #{amount} #{wallet.currency} " \
        "for #{wallet.customer}#{initiator_comment_suffix}."
      end

      def initiator_comment_suffix
        " by #{initiator}" if initiator
      end

      def create_balance_request!
        BalanceRequestBuilders::BonusChange.call(entry_request, bonus: amount)
      end
    end
  end
end
