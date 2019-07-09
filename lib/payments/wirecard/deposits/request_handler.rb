# frozen_string_literal: true

module Payments
  module Wirecard
    module Deposits
      class RequestHandler < ApplicationService
        def initialize(transaction:, client:)
          @transaction = transaction
          @client = client
        end

        def call
          request_payment_session['payment-redirect-url']
        end

        private

        attr_reader :transaction, :client

        def request_payment_session
          response = client.authorize_payment(transaction)
          response.parsed_response
        rescue ::HTTParty::ResponseError => error
          Rails.logger.error(error)
          raise ::Payments::GatewayError, 'Technical gateway error'
        end
      end
    end
  end
end
