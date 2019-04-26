# frozen_string_literal: true

module EntryRequests
  module Factories
    class BetPlacement < ApplicationService
      delegate :odd, :market, to: :bet

      def initialize(bet:, initiator: nil)
        @bet = bet
        @passed_initiator = initiator
      end

      def call
        create_entry_request!
        validate_entry_request!
        create_balance_requests!

        entry_request
      end

      private

      attr_reader :bet, :passed_initiator, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        bet_attributes.merge(
          initiator: initiator,
          kind: EntryRequest::BET,
          mode: EntryRequest::SYSTEM,
          comment: comment
        )
      end

      def bet_attributes
        {
          amount: bet.amount,
          currency: bet.currency,
          customer: bet.customer,
          origin: bet
        }
      end

      def initiator
        passed_initiator || bet.customer
      end

      def comment
        "Withdrawal #{bet.amount} #{bet.currency} " \
        "for #{bet.customer}#{initiator_comment_suffix}"
      end

      def initiator_comment_suffix
        " by #{passed_initiator}" if passed_initiator
      end

      def validate_entry_request!
        ::Bets::PlacementForm.new(subject: bet).validate!
      rescue Bets::PlacementError => error
        entry_request.register_failure!(error.message)
      end

      def create_balance_requests!
        BalanceRequestBuilders::Bet.call(entry_request, amount_calculations)
      end

      def amount_calculations
        BalanceCalculations::Bet.call(bet: bet)
      end
    end
  end
end
