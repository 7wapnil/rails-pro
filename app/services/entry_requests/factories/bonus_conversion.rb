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
        EntryRequest.create!(entry_request_attributes)
      end

      attr_reader :customer_bonus, :amount

      private

      def entry_request_attributes
        {
          amount: amount,
          real_money_amount: amount,
          converted_bonus_amount: amount,
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
    end
  end
end
