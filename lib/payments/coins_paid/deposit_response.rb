# frozen_string_literal: true

module Payments
  module CoinsPaid
    class DepositResponse < ::Payments::DepositResponse
      include Statuses

      M_BTC_MULTIPLIER = 1000
      FINISH_STATES = %w[succeeded failed].freeze

      def initialize(response)
        @response = response
      end

      def call
        return if entry_finished_state?
        return if pending?

        validate_currency!
        update_amount_on_demand
        return success_flow if confirmed?

        cancel_flow
      end

      private

      def entry_finished_state?
        FINISH_STATES.include?(entry_request.status)
      end

      def pending?
        response['status'] == NOT_CONFIRMED
      end

      def update_amount_on_demand
        return if entry_request.amount == converted_amount

        message =
          "Amount has been changed from #{entry_request.amount}
           to #{converted_amount}"

        entry_request.update(
          amount: converted_amount,
          result: {
            message: message
          }
        )
      end

      def validate_currency!
        return if Currencies::BTC_CODE != response['currency']

        entry_request.register_failure!('Wrong deposit currency')

        raise StandardError
      end

      def confirmed?
        response['status'] == CONFIRMED
      end

      def success_flow
        EntryRequests::DepositService.call(entry_request: entry_request)
      end

      def cancel_flow
        entry_request.register_failure!(message)
        fail_bonus
      end

      def message
        case status
        when CONFIRMED
          I18n.t('payments.deposits.coins_paid.statuses.confirmed')
        when NOT_CONFIRMED
          I18n.t('payments.deposits.coins_paid.statuses.not_confirmed')
        when ERROR
          I18n.t('payments.deposits.coins_paid.statuses.error')
        when CANCELLED
          I18n.t('payments.deposits.coins_paid.statuses.cancelled')
        when NOT_ENOUGH_FEE
          I18n.t('payments.deposits.coins_paid.statuses.not_enough_fee')
        end
      end

      def request_id
        response['foreign_id']
      end

      def status
        response['status']
      end

      def converted_amount
        response['amount'] * M_BTC_MULTIPLIER
      end
    end
  end
end
