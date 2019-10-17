# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        class RequestHandler < ApplicationService
          include ::Payments::Methods
          include Statuses

          delegate :deposit, to: :entry_request

          def initialize(transaction)
            @transaction = transaction
          end

          def call
            validate_request_params!
            send_receive_deposit_url_request
            validate_response!

            response['paymentPageUrl']
          rescue ::SafeCharge::InvalidParameterError => error
            fail_entry_request!(error.message)
          rescue ::SafeCharge::ApiError => error
            log_external_request_error(error)
            fail_entry_request!(error.message)
          end

          private

          attr_reader :transaction, :response, :entry_request

          def validate_request_params!
            RequestValidator.call(deposit_params)
          end

          def send_receive_deposit_url_request
            @response = client.receive_deposit_redirect_url(deposit_params)
          end

          def validate_response!
            return if response.ok? && valid_response?

            raise ::SafeCharge::ApiError, response['reason']
          end

          def fail_entry_request!(message)
            @entry_request = EntryRequest.find(deposit_params[:clientRequestId])
            entry_request.register_failure!(message)
            fail_related_entities!

            raise ::SafeCharge::InvalidPaymentUrlError, message
          end

          def log_external_request_error(error)
            Rails.logger.error(error_object: error, message: error.message)
          end

          def deposit_params
            @deposit_params ||= Deposits::RequestBuilder.call(transaction)
          end

          def client
            Client.new
          end

          def valid_response?
            response['status'] == SUCCESS
          end

          def fail_related_entities!
            deposit&.failed!
            deposit&.customer_bonus&.fail!
          end
        end
      end
    end
  end
end
