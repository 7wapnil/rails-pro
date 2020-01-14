# frozen_string_literal: true

module EveryMatrix
  module Requests
    class RollbackService < TransactionService
      private

      def request_name
        'Rollback'
      end

      def transaction_class
        EveryMatrix::Rollback
      end

      def placement_service
        EntryRequests::Factories::EveryMatrix::RollbackPlacement
      end

      def update_game_round_status!
        game_round.rollback!
      end

      def entry_creation_failed
        common_response.merge(
          'ReturnCode' => MAX_STAKE_LIMIT_EXCEEDED_CODE,
          'Message'    => transaction.entry_request.result['message']
        )
      end

      def valid_request?
        transaction.wager_entry.present? &&
          transaction.amount == transaction.wager.amount
      end

      def validation_failed
        common_response.merge(
          'ReturnCode' => TRANSACTION_NOT_FOUND_CODE,
          'Message'    => TRANSACTION_NOT_FOUND_MESSAGE
        )
      end
    end
  end
end
