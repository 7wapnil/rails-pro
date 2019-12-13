# frozen_string_literal: true

module EveryMatrix
  module Requests
    # rubocop:disable Metrics/ClassLength
    class TransactionService < SessionRequestService
      include CurrencyDenomination

      TRANSACTION_PARAMS = %w[Amount Device GameType
                              GPGameId EMGameId GPId
                              Product RoundId TransactionId
                              RoundStatus].freeze

      def initialize(params)
        super

        @amount = denominate_request_amount(
          code: currency_code,
          amount: transaction_params['Amount']&.to_d
        )
      end

      def call
        return transaction.response if find_transaction

        return user_not_found_response unless customer

        create_transaction!

        return record_response(validation_failed) unless valid_request?

        process_transaction!

        return record_response(entry_creation_failed) unless transaction.entry

        return record_response(post_process_failed) unless post_process

        update_summary_casino_wager_amounts!

        record_response(success_response)
      end

      protected

      attr_reader :amount, :transaction

      delegate :entry_request, :customer_bonus,
               to: :transaction

      def find_transaction
        @transaction =
          transaction_class
          .find_by(
            transaction_id: transaction_params['TransactionId']
          )
      end

      def process_transaction!
        create_entry_request!
        process_entry_request!
      end

      def create_transaction!
        @transaction =
          transaction_class
          .create!(
            attributes.merge(
              transaction_id: transaction_params['TransactionId']
            )
          )
      end

      def attributes
        {
          customer:          customer,
          wallet_session: session,
          amount:            amount.to_d,
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
        placement_service.call(transaction: transaction)
      end

      def process_entry_request!
        EntryRequests::ProcessingService.call(entry_request: entry_request)
      end

      def update_summary_casino_wager_amounts!
        Customers::Summaries::BalanceUpdateWorker.perform_async(
          Date.current,
          transaction.entry.id
        )
      end

      def success_response
        common_success_response.merge(balance_calculation_response)
      end

      def balance_calculation_response
        BalanceCalculationService.call(
          session: session,
          balance_only: true
        ).merge(
          'SessionId'            => session.id,
          'AccountTransactionId' => transaction.id
        )
      end

      def balance_amount_after
        wallet.amount
      end

      def response_currency_code
        denominate_currency_code(code: currency_code)
      end

      def response_balance_amount
        denominate_response_amount(
          code: currency_code,
          amount: balance_amount_after
        )
      end

      def record_response(response)
        transaction.update_attributes!(response: response)

        response
      end

      def valid_request?
        true
      end

      def validation_failed
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end

      def entry_creation_failed
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end

      def transaction_class
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end

      def placement_service
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end

      def post_process
        true
      end

      def post_process_failed
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
