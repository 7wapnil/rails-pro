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

        success_response
      end

      protected

      def request_name
        'Result'
      end

      private

      attr_reader :amount

      def result_params
        @result_params ||=
          params.permit(*RESULT_PARAMS)
      end

      def success_response
        common_success_response.merge(
          'SessionId'            => session.id,
          'AccountTransactionId' => 12345,
          'Currency'             => currency_code,
          'Balance'              => (wallet.amount + amount).to_d.to_s
        )
      end
    end
  end
end
