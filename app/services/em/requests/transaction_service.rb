# frozen_string_literal: true

module Em
  module Requests
    class TransactionService < BaseRequestService
      TRANSACTION_PARAMS = %w[Amount Device GameType
                              GPGameId EMGameId GPId
                              Product RoundId TransactionId
                              RoundStatus].freeze

      def initialize(params)
        super

        @amount = transaction_params['Amount']&.to_d
      end

      def call
        return user_not_found_response unless customer

        create_transaction!
        create_entry_request!
        process_entry_request!

        success_response
      end

      protected

      attr_reader :amount, :transaction, :entry_request

      def create_transaction!
        @transaction =
          transaction_class
          .find_or_initialize_by(
            transaction_id: transaction_params['TransactionId']
          )

        @transaction.update_attributes(attributes) if @transaction.new_record?
      end

      def attributes
        {
          customer:          customer,
          em_wallet_session: session,
          amount:            transaction_params['Amount'].to_d,
          game_type:         transaction_params['GameType'],
          gp_game_id:        transaction_params['GPGameId'],
          gp_id:             transaction_params['GPId'],
          em_game_id:        transaction_params['EMGameId'],
          product:           transaction_params['Product'],
          round_id:          transaction_params['RoundId'],
          device:            transaction_params['Device'],
          round_status:      transaction_params['RoundStatus']
        }
      end

      def transaction_params
        @transaction_params ||= params.permit(*TRANSACTION_PARAMS)
      end

      def create_entry_request!
        @entry_request = placement_service.call(transaction: transaction)
      end

      def process_entry_request!
        EntryRequests::ProcessingService.call(entry_request: entry_request)
      end

      def success_response
        common_success_response.merge(
          'SessionId'            => session.id,
          'AccountTransactionId' => transaction.id,
          'Currency'             => currency_code,
          'Balance'              => wallet.reload.amount.to_d.to_s
        )
      end

      def transaction_class
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end

      def placement_service
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end
    end
  end
end
