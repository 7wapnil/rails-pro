module EntryRequests
  module Factories
    class Withdraw < ApplicationService
      def initialize(wallet:, amount:, mode: EntryRequest::CASHIER, **attrs)
        @wallet = wallet
        @amount = amount
        @mode = mode
        @comment = attrs[:comment]
        @initiator = attrs[:initiator] || wallet.customer
        @origin = attrs[:origin]
      end

      def call
        create_entry_request!
        create_balance_entry_request!
        entry_request
      end

      private

      attr_reader :wallet, :mode, :entry_request, :comment, :initiator

      def amount
        -@amount.abs
      end

      def create_entry_request!
        @entry_request = EntryRequest.create!(
          kind: EntryRequest::WITHDRAW,
          currency: wallet.currency,
          customer: wallet.customer,
          amount: amount,
          initiator: wallet.customer,
          mode: mode,
          comment: comment
        )
      end

      def create_balance_entry_request!
        BalanceRequestBuilders::Withdraw.call(entry_request, real_money: amount)
      end
    end
  end
end
