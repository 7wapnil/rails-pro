# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        # rubocop:disable Metrics/ClassLength
        class RequestHandler < ApplicationService
          include ::Payments::Methods
          include Rails.application.routes.url_helpers

          API_VERSION = '4.0.0'

          TIMESTAMP_FORMAT = '%Y-%m-%d.%H:%M:%S'
          DATE_OF_BIRTH_FORMAT = '%Y-%m-%d'
          ITEM_QUANTITY = 1
          IS_NATIVE = 1
          FILTER_MODE = 'filter'
          DEFAULT_WEB_PROTOCOL = 'https'

          delegate :customer, :currency, :amount, to: :transaction
          delegate :address, to: :customer, prefix: true
          delegate :street_address, :city, :country_code, :zip_code,
                   to: :customer_address, allow_nil: true, prefix: true

          def initialize(transaction, **extra_query_params)
            @transaction = transaction
            @extra_query_params = extra_query_params
          end

          def call
            validate!

            "#{base_url}?#{query}"
          end

          private

          attr_reader :transaction, :extra_query_params

          def validate!
            PaymentUrlValidator.call(url: base_url,
                                     query_hash: query_hash_with_checksum)
          end

          def base_url
            @base_url ||= ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
          end

          def query
            URI.encode_www_form(query_hash_with_checksum)
          end

          def query_hash_with_checksum
            @query_hash_with_checksum ||= query_hash.merge(checksum: checksum)
          end

          # TODO: Take country and state from db
          def query_hash # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            @query_hash ||= {
              merchant_id: ENV['SAFECHARGE_MERCHANT_ID'],
              merchant_site_id: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              version: API_VERSION,
              encoding: encoding,
              time_stamp: timestamp,
              currency: currency_code,
              userid: customer.id,
              productId: transaction.id,
              user_token_id: customer.id,
              item_name_1: extra_query_params.fetch(:item_name_1) { item_name },
              item_number_1: transaction.id,
              item_amount_1: transaction.amount,
              item_quantity_1: ITEM_QUANTITY,
              total_amount: transaction.amount,
              first_name: customer.first_name,
              last_name: customer.last_name,
              email: customer.email,
              phone1: customer.phone,
              dateOfBirth: customer_date_of_birth,
              address1: customer_address_street_address,
              city: customer_address_city,
              country: customer_address_country_code, # TODO: Take from db
              state: customer_address_state_code, # TODO: Take from db
              zip: customer_address_zip_code,
              isNative: extra_query_params.fetch(:isNative, IS_NATIVE),
              payment_method: provider_method_name(transaction.method),
              payment_method_mode: FILTER_MODE,
              success_url: success_redirection_url,
              error_url: webhook_url,
              pending_url: webhook_url,
              back_url: cancellation_redirection_url,
              notify_url: webhook_url
            }
          end

          def encoding
            extra_query_params.fetch(:encoding) { Encoding::UTF_8.to_s }
          end

          def timestamp
            return specified_timestamp if specified_timestamp.is_a?(String)

            specified_timestamp&.strftime(TIMESTAMP_FORMAT)
          end

          def specified_timestamp
            @specified_timestamp ||= extra_query_params
                                     .fetch(:time_stamp) { Time.zone.now }
          end

          def item_name
            "Deposit #{transaction.amount} to your #{currency_code} wallet " \
            "on #{ENV['BRAND_NAME']}"
          end

          def currency_code
            @currency_code ||= extra_query_params
                               .fetch(:currency_code) { currency.code }
          end

          def customer_date_of_birth
            customer.date_of_birth&.strftime(DATE_OF_BIRTH_FORMAT)
          end

          # TODO: remove when states would be handled on back-end
          def customer_address_state_code
            customer_address.state_code if with_state?
          end

          def with_state?
            State::AVAILABLE_STATES.key?(customer_address_country_code)
          end

          # Don't become confused.
          # Success redirection response is received on
          # GET payments#show
          def success_redirection_url
            webhook_url
          end

          # Webhook response is received on
          # POST payments#create
          def webhook_url
            webhooks_safe_charge_payment_url(
              host: ENV['APP_HOST'],
              protocol: web_protocol,
              request_id: transaction.id
            )
          end

          def web_protocol
            @web_protocol ||= ENV.fetch('WEB_PROTOCOL', DEFAULT_WEB_PROTOCOL)
          end

          # Cancellation redirection response is received on
          # GET cancelled_payments#show
          def cancellation_redirection_url
            webhooks_safe_charge_payment_cancel_url(
              host: ENV['APP_HOST'],
              protocol: web_protocol,
              request_id: transaction.id,
              signature: cancellation_signature
            )
          end

          def cancellation_signature
            OpenSSL::HMAC.hexdigest(
              CancellationSignatureVerifier::SIGNATURE_ALGORITHM,
              ENV['SAFECHARGE_SECRET_KEY'],
              transaction.id.to_s
            )
          end

          def checksum
            Digest::SHA256.hexdigest(checksum_string)
          end

          def checksum_string
            [
              ENV['SAFECHARGE_SECRET_KEY'],
              *query_hash.values
            ].map(&:to_s).join
          end
          # rubocop:enable Metrics/ClassLength
        end
      end
    end
  end
end
