# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        # rubocop:disable Metrics/ClassLength
        class RequestBuilder < ApplicationService
          include ::Payments::Methods
          include Rails.application.routes.url_helpers

          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'
          DATE_OF_BIRTH_FORMAT = '%Y-%m-%d'
          ITEM_QUANTITY = 1
          IS_NATIVE = 1
          FILTER_MODE = 'filter'
          DEFAULT_WEB_PROTOCOL = 'https'
          OPEN_AMOUNT = false
          MAX_AMOUNT_LIMIT = 9_999_999
          DECIMAL_LIMIT = 2

          delegate :customer, :currency, :amount, to: :transaction
          delegate :address, to: :customer, prefix: true
          delegate :street_address, :city, :country_code, :zip_code,
                   to: :customer_address, allow_nil: true, prefix: true
          delegate :code, to: :currency, allow_nil: true, prefix: true

          def initialize(transaction)
            @transaction = transaction
          end

          def call # rubocop:disable Metrics/MethodLength
            {
              merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
              merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              userTokenId: user_token_id,
              clientUniqueId: customer.id,
              clientRequestId: transaction.id,
              currency: currency_code,
              amount: transaction.amount,
              amountDetails: amount_details,
              items: items_details,
              billingAddress: billing_address,
              urlDetails: url_details,
              paymentMethod: provider_method_name(transaction.method),
              paymentMethodMode: FILTER_MODE,
              isNative: IS_NATIVE,
              timeStamp: timestamp,
              checksum: checksum
            }
          end

          private

          attr_reader :transaction

          def user_token_id
            transaction.method == IDEBIT ? "000#{customer.id}" : customer.id
          end

          def amount_details
            {
              totalShipping: 0,
              totalHandling: 0,
              totalDiscount: 0,
              totalTax: 0,
              itemOpenAmount1: OPEN_AMOUNT,
              itemMinAmount1: currency_rule&.min_amount,
              itemMaxAmount1: max_amount,
              numberOfItems: ITEM_QUANTITY
            }
          end

          def max_amount
            [currency_rule&.max_amount, MAX_AMOUNT_LIMIT]
              .min_by(&:to_f)
              .round(DECIMAL_LIMIT)
          end

          def items_details
            [
              {
                name: item_name,
                price: transaction.amount,
                quantity: ITEM_QUANTITY
              }
            ]
          end

          def billing_address
            {
              firstName: customer.first_name,
              lastName: customer.last_name,
              address: customer_address_street_address,
              phone: customer.phone,
              zip: customer_address_zip_code,
              city: customer_address_city,
              country: customer_address_country_code,
              state: customer_address_state_code,
              email: customer.email
            }
          end

          def url_details
            {
              successUrl: success_redirection_url,
              failureUrl: webhook_url,
              pendingUrl: webhook_url,
              notificationUrl: webhook_url,
              backUrl: cancellation_redirection_url
            }
          end

          def checksum
            Digest::SHA256.hexdigest(checksum_string)
          end

          def currency_rule
            @currency_rule ||= currency
                               .entry_currency_rules
                               .find_by(kind: EntryKinds::DEPOSIT)
          end

          def timestamp
            specified_timestamp.strftime(TIMESTAMP_FORMAT)
          end

          def specified_timestamp
            @specified_timestamp ||= Time.zone.now
          end

          def item_name
            "Deposit #{transaction.amount} to your #{currency_code} wallet " \
            "on #{ENV['BRAND_NAME']}"
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

          def checksum_string
            [
              ENV['SAFECHARGE_MERCHANT_ID'],
              ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              transaction.id,
              transaction.amount,
              currency_code,
              timestamp,
              ENV['SAFECHARGE_SECRET_KEY']
            ].map(&:to_s).join
          end
          # rubocop:enable Metrics/ClassLength
        end
      end
    end
  end
end
