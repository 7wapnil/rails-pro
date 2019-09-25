# frozen_string_literal: true

module Em
  module Requests
    class ResultService < BaseRequestService
      RESULT_PARAMS = %w[Amount Device GameType
                         GPGameId EMGameId GPId
                         Product RoundId TransactionId
                         RoundStatus].freeze

      def initialize(params)
        super

        @amount = result_params['Amount']&.to_d
      end

      def call
        return user_not_found_response unless customer

        create_result!
        create_entry_request!
        process_entry_request!

        success_response
      end

      protected

      def request_name
        'Result'
      end

      private

      attr_reader :amount, :result, :entry_request

      def create_result!
        @result = Result.find_or_initialize_by(
          transaction_id: result_params['TransactionId']
        )

        @result.update_attributes!(result_attributes) if @result.new_record?
      end

      def result_params
        @result_params ||=
          params.permit(*RESULT_PARAMS)
      end

      def result_attributes
        {
          customer:          customer,
          em_wallet_session: session,
          amount:            result_params['Amount'].to_d,
          game_type:         result_params['GameType'],
          gp_game_id:        result_params['GPGameId'],
          gp_id:             result_params['GPId'],
          em_game_id:        result_params['EMGameId'],
          product:           result_params['Product'],
          round_id:          result_params['RoundId'],
          device:            result_params['Device'],
          round_status:      result_params['RoundStatus']
        }
      end

      def create_entry_request!
        @entry_request =
          EntryRequests::Factories::EmResultPlacement.call(result: result)
      end

      def process_entry_request!
        EntryRequests::ProcessingService.call(entry_request: entry_request)
      end

      def success_response
        common_success_response.merge(
          'SessionId'            => session.id,
          'AccountTransactionId' => result.id,
          'Currency'             => currency_code,
          'Balance'              => (wallet.amount + amount).to_d.to_s
        )
      end
    end
  end
end
