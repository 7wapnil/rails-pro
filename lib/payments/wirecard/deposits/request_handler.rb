# frozen_string_literal: true

module Payments
  module Wirecard
    module Deposits
      class RequestHandler < ApplicationService
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
          Rails.logger.error(error)
          raise ::Payments::GatewayError, 'Technical gateway error'
        end

        def client
          @client ||= Client.new
        end
      end
    end
  end
end
