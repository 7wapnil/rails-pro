# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module OrderDetails
        class RequestHandler < ApplicationService
          include Statuses
          include ErrorCodes

          def initialize(transaction:, order_id:)
            @transaction = transaction
            @order_id = order_id
          end

          def call
            return unsuccessful_request_error_message unless success?

            error_message
          end

          private

          attr_reader :transaction, :order_id

          def unsuccessful_request_error_message
            return response['reason'] unless response['reason'].blank?
            return response['gwReason'] unless response['gwReason'].blank?

            default_error_message
          end

          def success?
            response.ok? && success_request?
          end

          def error_message
            return default_error_message unless gateway_error?

            error_message_by_code(order_details['extendedErrorCode'])
          end

          def response
            @response ||= client.receive_order_details(order_params)
          end

          def default_error_message
            I18n.t('errors.messages.withdrawal.no_order_details', id: order_id)
          end

          def client
            Client.new
          end

          def order_params
            RequestBuilder.call(
              transaction: transaction,
              order_id: order_id
            )
          end

          def success_request?
            response['status'] == SUCCESS
          end

          def gateway_error?
            return false unless order_details

            order_details['errorCode'] == GATEWAY_FILTER_ERROR_CODE
          end

          def order_details
            response['withdrawalOrders'].find do |order|
              order['wdOrderId'] == order_id
            end
          end
        end
      end
    end
  end
end
