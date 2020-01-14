# frozen_string_literal: true

module EveryMatrix
  module Requests
    class WagerService < TransactionService
      def call
        super.tap do |response|
          next if response&.dig('ReturnCode') != SUCCESS_CODE

          update_summary_casino_customer_ids!
        end
      end

      def post_process_service
        WagerSettlementService
      end

      private

      def update_summary_casino_customer_ids!
        Customers::Summaries::UpdateWorker.perform_async(
          Date.current,
          casino_customer_ids: customer.id
        )
      end

      def request_name
        'Wager'
      end

      def transaction_class
        EveryMatrix::Wager
      end

      def placement_service
        EntryRequests::Factories::EveryMatrix::WagerPlacement
      end

      def update_game_round_status!
        true
      end

      def insufficient_funds?
        wallet && (amount > available_amount)
      end

      def available_amount
        return wallet.amount if bonus?

        wallet.real_money_balance
      end

      def bonus?
        wallet.customer_bonus&.active? && wallet.customer_bonus&.casino?
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
