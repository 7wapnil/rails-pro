module EntryRequests
  module Factories
    class Deposit < ApplicationService
      def initialize(wallet:, amount:, **attributes)
        @wallet = wallet
        @amount = amount
        @initiator = attributes[:initiator] || wallet.customer
        @mode = attributes[:mode] || EntryRequest::CASHIER
        @passed_comment = attributes[:comment]
        @customer_bonus = wallet.customer.customer_bonus
      end

      def call
        create_entry_request!
        create_balance_request!

        entry_request
      end

      private

      attr_reader :wallet, :amount, :initiator, :mode,
                  :passed_comment, :customer_bonus, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        wallet_attributes.merge(
          amount: amount_value,
          mode: mode,
          kind: EntryRequest::DEPOSIT,
          comment: comment,
          initiator: initiator
        )
      end

      def wallet_attributes
        {
          origin:   wallet,
          currency: wallet.currency,
          customer: wallet.customer
        }
      end

      def amount_value
        @amount_value ||= calculations.values.sum
      end

      def calculations
        @calculations ||=
          BalanceCalculations::Deposit
          .call(customer_bonus, amount)
          .tap { |amounts| amounts[:bonus] = 0 unless eligible_for_bonus? }
      end

      def comment
        passed_comment.presence ||
          "Deposit #{amount_value} #{wallet.currency} for #{initiator}"
      end

      def create_balance_request!
        BalanceRequestBuilders::Deposit.call(entry_request, calculations)
      end

      def eligible_for_bonus?
        customer_bonus.present? && customer_bonus.eligible_with?(amount)
      end
    end
  end
end
