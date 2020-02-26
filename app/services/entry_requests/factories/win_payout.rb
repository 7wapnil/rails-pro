# frozen_string_literal: true

module EntryRequests
  module Factories
    class WinPayout < ApplicationService
      def initialize(origin:, **attributes)
        @bet = origin
        @attributes = attributes
      end

      def call
        EntryRequest.create!(entry_request_attributes)
      end

      private

      attr_reader :bet, :attributes

      def entry_request_attributes
        attributes
          .merge(origin_attributes)
          .merge(balance_attributes)
          .merge(amount: adjusted_amount)
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
        @balance_attributes ||= Bets::Clerk.call(
          bet: bet,
          origin: Entry.new(balance_calculations)
        )
      end

      def balance_calculations
        BalanceCalculations::BetCompensation.call(
          bet: bet,
          amount: requested_total_amount
        )
      end

      def requested_total_amount
        attributes[:amount] || 0
      end

      def adjusted_amount
        balance_attributes
          .slice(:real_money_amount, :bonus_amount)
          .values
          .map { |amount| amount.round(bet.currency.scale) }
          .reduce(:+)
      end

      def initiator
        attributes.fetch(:initiator) { bet.customer }
      end
    end
  end
end
