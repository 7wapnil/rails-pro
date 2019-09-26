# frozen_string_literal: true

module Em
  module Requests
    class WagerService < TransactionService
      def call
        return insufficient_funds_response if insufficient_funds?

        super
      end

      protected

      def request_name
        'Wager'
      end

      def transaction_class
        Em::Wager
      end

      def placement_service
        EntryRequests::Factories::EmWagerPlacement
      end

      private

      def insufficient_funds?
        wallet && (amount > wallet.amount)
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
