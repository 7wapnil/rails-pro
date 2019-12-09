# frozen_string_literal: true

module EntryRequests
  module Factories
    class Rollback < ApplicationService
      def initialize(bet_leg:)
        @bet_leg = bet_leg
        @bet = bet_leg.bet
      end

      def call
        EntryRequest.create!(entry_request_attributes)
      end

      private

      attr_reader :bet, :bet_leg

      def entry_request_attributes
        {
          kind: EntryKinds::ROLLBACK,
          mode: EntryRequest::INTERNAL,
          amount: -winning_entry.amount,
          comment: comment,
          customer_id: bet.customer_id,
          currency_id: bet.currency_id,
          origin: bet,
          real_money_amount: -winning_entry.real_money_amount,
          bonus_amount: -winning_entry.bonus_amount
        }
      end

      def winning_entry
        @winning_entry ||= bet.winning
      end

      def comment
        "Rollback won amount #{winning_entry.amount} #{bet.currency} " \
        "for #{bet.customer} on #{bet_leg.event}."
      end
    end
  end
end
