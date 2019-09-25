# frozen_string_literal: true

module Em
  module Requests
    class WagerService < BaseRequestService
      WAGER_PARAMS = %w[Amount Device GameType
                        GPGameId EMGameId GPId
                        Product RoundId TransactionId
                        RoundStatus].freeze
      def initialize(params)
        super

        @amount = wager_params['Amount']&.to_d
      end

      def call
        return user_not_found_response unless customer

        return insufficient_funds_response if insufficient_funds?

        create_wager!
        create_entry_request!
        process_entry_request!

        success_response
      end

      protected

      def request_name
        'Wager'
      end

      private

      attr_reader :amount, :wager, :entry_request

      def insufficient_funds?
        amount > wallet.amount
      end

      def insufficient_funds_response
        common_response.merge(
          'ReturnCode' => 104,
          'Message'    => 'Insufficient funds'
        )
      end

      def create_wager!
        @wager = Wager.find_or_initialize_by(
          transaction_id: wager_params['TransactionId']
        )

        @wager.update_attributes!(wager_attributes) if @wager.new_record?
      end

      def wager_params
        @wager_params ||= params.permit(*WAGER_PARAMS)
      end

      def wager_attributes
        {
          customer:          customer,
          em_wallet_session: session,
          amount:            wager_params['Amount'].to_d,
          game_type:         wager_params['GameType'],
          gp_game_id:        wager_params['GPGameId'],
          gp_id:             wager_params['GPId'],
          em_game_id:        wager_params['EMGameId'],
          product:           wager_params['Product'],
          round_id:          wager_params['RoundId'],
          device:            wager_params['Device'],
          round_status:      wager_params['RoundStatus']
        }
      end

      def create_entry_request!
        @entry_request =
          EntryRequests::Factories::EmWagerPlacement.call(wager: wager)
      end

      def process_entry_request!
        EntryRequests::ProcessingService.call(entry_request: entry_request)
      end

      def success_response
        common_success_response.merge(
          'SessionId'            => session.id,
          'AccountTransactionId' => wager.id,
          'Currency'             => currency_code,
          'Balance'              => wallet.reload.amount.to_d.to_s
        )
      end
    end
  end
end
