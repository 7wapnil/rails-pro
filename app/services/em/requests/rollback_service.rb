# frozen_string_literal: true

module Em
  module Requests
    class RollbackService < BaseRequestService
      RESULT_PARAMS = %w[Amount Device GameType
                         GPGameId EMGameId GPId
                         Product RoundId TransactionId
                         RoundStatus].freeze

      def initialize(params)
        super

        @amount = rollback_params['Amount']&.to_d
      end

      def call
        return user_not_found_response unless customer

        create_rollback!
        create_entry_request!
        process_entry_request!

        success_response
      end

      protected

      def request_name
        'Rollback'
      end

      private

      attr_reader :amount, :rollback, :entry_request

      def create_rollback!
        @rollback = Rollback.find_or_initialize_by(
          transaction_id: rollback_params['TransactionId']
        )

        @rollback.update_attributes!(rollback_attrs) if @rollback.new_record?
      end

      def rollback_params
        @rollback_params ||=
          params.permit(*RESULT_PARAMS)
      end

      def rollback_attrs
        {
          customer:          customer,
          em_wallet_session: session,
          amount:            rollback_params['Amount'].to_d,
          game_type:         rollback_params['GameType'],
          gp_game_id:        rollback_params['GPGameId'],
          gp_id:             rollback_params['GPId'],
          em_game_id:        rollback_params['EMGameId'],
          product:           rollback_params['Product'],
          round_id:          rollback_params['RoundId'],
          device:            rollback_params['Device'],
          round_status:      rollback_params['RoundStatus']
        }
      end

      def create_entry_request!
        @entry_request =
          EntryRequests::Factories::EmRollbackPlacement.call(rollback: rollback)
      end

      def process_entry_request!
        EntryRequests::ProcessingService.call(entry_request: entry_request)
      end

      def success_response
        common_success_response.merge(
          'SessionId'            => session.id,
          'AccountTransactionId' => rollback.id,
          'Currency'             => currency_code,
          'Balance'              => wallet.reload.amount.to_d.to_s
        )
      end
    end
  end
end
