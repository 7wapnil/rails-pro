# frozen_string_literal: true

module EntryRequests
  module Factories
    class WinPayout < ApplicationService
      def initialize(origin:, **attributes)
        @bet = origin
        @attributes = attributes
      end

      def call
        create_entry_request!
        adjust_amount!

        entry_request
      end

      private

      attr_reader :bet, :entry_request, :attributes

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        attributes
          .merge(origin_attributes)
          .merge(balance_attributes)
      end

      def origin_attributes
        return {} unless bet

        {
          currency: bet.currency,
          initiator: initiator,
          customer: bet.customer,
          origin: bet
        }
      end

      def balance_attributes
        return balance_calculations if bet&.customer_bonus&.active?

        balance_calculations.slice(:real_money_amount)
      end

      def balance_calculations
        @balance_calculations ||= BalanceCalculations::BetCompensation.call(
          bet: bet,
          amount: requested_total_amount
        )
      end

      def requested_total_amount
        attributes[:amount] || 0
      end

      def adjust_amount!
        new_amount = entry_request.real_money_amount +
                     entry_request.bonus_amount
        entry_request.update(amount: new_amount)
      end

      def initiator
        return bet.customer unless attributes.key?(:initiator)

        attributes[:initiator]
      end
    end
  end
end
