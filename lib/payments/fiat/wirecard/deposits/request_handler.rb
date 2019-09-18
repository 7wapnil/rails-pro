# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      module Deposits
        class RequestHandler < ApplicationService
          CURRENCY_ERROR_CODE = 'E7001'

          def initialize(transaction:)
            @transaction = transaction
          end

          def call
            request_payment_session['payment-redirect-url']
          end

          private

          attr_reader :transaction

          def request_payment_session
            response = client.authorize_payment(transaction)
            response.parsed_response
          rescue ::HTTParty::ResponseError => error
            Rails.logger.error(error_object: error, message: error.message)

            raise ::Payments::GatewayError, gateway_error_message(error)
          end

          def client
            @client ||= Client.new
          end

          def gateway_error_message(error)
            currency_error = I18n.t(
              'errors.messages.payments.deposits.currency_error'
            )

            return currency_error if error.message.include?(CURRENCY_ERROR_CODE)

            I18n.t('errors.messages.payments.gateway_error')
          end
        end
      end
    end
  end
end
