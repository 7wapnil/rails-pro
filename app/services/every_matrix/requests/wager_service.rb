# frozen_string_literal: true

module EveryMatrix
  module Requests
    class WagerService < TransactionService
      def post_process
        WagerSettlementService.call(transaction)
      end

      def post_process_failed
        common_response.merge(
          'ReturnCode' => INSUFFICIENT_FUNDS_CODE,
          'Message'    => "#{INSUFFICIENT_FUNDS_MESSAGE} (from post-processing)"
        )
      end

      private

      def request_name
        'Wager'
      end

      def transaction_class
        EveryMatrix::Wager
      end

      def placement_service
        EntryRequests::Factories::EveryMatrix::WagerPlacement
      end

      def insufficient_funds?
        wallet && (amount > available_amount)
      end

      def available_amount
        return wallet.amount if bonus?

        wallet.real_money_balance
      end

      def bonus?
        customer_bonus&.active? && customer_bonus&.casino?
      end

      def valid_request?
        !insufficient_funds?
      end

      def validation_failed
        insufficient_funds_response
      end

      def insufficient_funds_response
        common_response.merge(
          'ReturnCode' => INSUFFICIENT_FUNDS_CODE,
          'Message'    => INSUFFICIENT_FUNDS_MESSAGE
        )
      end

      def entry_creation_failed
        common_response.merge(
          'ReturnCode' => MAX_STAKE_LIMIT_EXCEEDED_CODE,
          'Message'    => MAX_STAKE_LIMIT_EXCEEDED_MESSAGE
        )
      end
    end
  end
end
