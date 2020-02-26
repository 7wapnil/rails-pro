# frozen_string_literal: true

module EntryRequests
  module Factories
    class BetRefund < ApplicationService
      delegate :placement_entry, to: :bet

      def initialize(bet:, **attributes)
        @bet = bet
        @attributes = attributes
      end

      def call
        EntryRequest.create!(entry_request_attributes)
      end

      private

      attr_reader :entry_request, :bet, :attributes

      def populate_mode
        placement_entry.entry_request&.mode || EntryRequest::CASHIER
      end

      def entry_request_attributes
        general_attributes
          .merge(attributes)
          .merge(balance_attributes)
      end

      def general_attributes
        {
          kind: EntryRequest::REFUND,
          mode: EntryRequest::INTERNAL,
          currency: bet.currency,
          initiator: bet.customer,
          customer: bet.customer,
          origin: bet
        }
      end

      def balance_attributes
        return original_balance_attributes unless bet.settled? &&
                                                  bet.void_factor

        original_balance_attributes.transform_values do |amount|
          (amount * bet.void_factor).round(bet.currency.scale)
        end
      end

      def original_balance_attributes
        Bets::Clerk.call(bet: bet, origin: placement_entry)
      end
    end
  end
end
