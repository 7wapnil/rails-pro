# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module PaymentDetails
        class RequestHandler < ApplicationService
          include ::Payments::Fiat::SafeCharge::Methods

          def initialize(entry_request:, payment_option_id:)
            @entry_request = entry_request
            @payment_option_id = payment_option_id&.to_s
          end

          def call
            entry_request.deposit.update(details: payment_details)
          end

          private

          attr_reader :entry_request, :payment_option_id

          def payment_details
            find_identical_payment_details || build_new_payment_details
          end

          def find_identical_payment_details
            entry_request
              .customer
              .entry_requests
              .select('customer_transactions.details')
              .joins(:deposit)
              .deposit
              .succeeded
              .where.not(id: entry_request.id)
              .find_by(
                "customer_transactions.details->>'user_payment_option_id' = ?",
                payment_option_id
              )
              &.details
          end

          def build_new_payment_details
            {
              user_payment_option_id: payment_option_id,
              name: scrap_payment_option_name
            }
          end

          def scrap_payment_option_name
            payment_option_info.dig('upoData', name_identifier).presence ||
              payment_option_info['upoName'].presence ||
              I18n.t("kinds.payment_methods.#{entry_request.mode}")
          end

          def payment_option_info
            response
              .fetch('paymentMethods', [])
              .find(&method(:payload_option_id_equal?))
              .to_h
          end

          def name_identifier
            NAME_IDENTIFIERS_MAP[entry_request.mode]
          end

          def response
            @response ||= client.receive_user_payment_options(options_params)
          end

          def client
            Client.new
          end

          def options_params
            RequestBuilder.call(entry_request: entry_request)
          end

          def payload_option_id_equal?(payload)
            payload.dig('userPaymentOptionId').to_s == payment_option_id
          end
        end
      end
    end
  end
end
