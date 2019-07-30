# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Payouts
        class RequestHandler < Handlers::PayoutRequestHandler
          include Statuses

          private

          def created?
            status_code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
          end

          def status_code
            request.code.to_i
          end

          def client
            ::Payments::Crypto::CoinsPaid::Client.new
          end

          def request
            @request ||= client.authorize_payout(transaction)
          end

          def response
            @response = JSON.parse(request.body)
          end

          def raw_error_message
            response['errors']&.values&.first
          end

          def error_message
            @error_message ||= "CoinsPaid: #{raw_error_message}"
          end
        end
      end
    end
  end
end