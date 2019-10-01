# frozen_string_literal: true

module EveryMatrix
  module Requests
    class WagerService < TransactionService
      def call
        super
      end

      protected

      def request_name
        'Wager'
      end

      def transaction_class
        EveryMatrix::Wager
      end

      def placement_service
        EntryRequests::Factories::EmWagerPlacement
      end

      private

      def insufficient_funds?
        wallet && (amount > wallet.real_money_balance)
      end

      def valid_request?
        !insufficient_funds?
      end

      def validation_failed
        insufficient_funds_response
      end

      def insufficient_funds_response
        common_response.merge(
          'ReturnCode' => 104,
          'Message'    => 'Insufficient funds'
        )
      end
    end
  end
end
