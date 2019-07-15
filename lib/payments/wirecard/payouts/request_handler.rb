# frozen_string_literal: true

module Payments
  module Wirecard
    module Payouts
      class RequestHandler < ::Payments::PayoutRequestHandler
        include Statuses

        def initialize(transaction)
          @transaction = transaction
        end

        private

        def created?
          succeeded_request? && succeeded_response?
        end

        def succeeded_request?
          request.code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
        end

        def succeeded_response?
          status_code == Rack::Utils::SYMBOL_TO_STATUS_CODE[:created]
        end

        def status_code
          response.dig('payment', 'statuses', 'status', 0, 'code').to_i
        end

        def client
          ::Payments::Wirecard::Client.new
        end

        def request
          @request ||= client.authorize_payout(transaction)
        end

        def response
          @response = JSON.parse(request.body)
        end

        def raw_error_message
          return request.message unless succeeded_request?

          response.dig('payment', 'statuses', 'status', 0, 'description')
        end

        def error_message
          @error_message ||= "Wirecard: #{raw_error_message}"
        end
      end
    end
  end
end
